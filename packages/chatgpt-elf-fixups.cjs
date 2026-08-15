#!/usr/bin/env node
// Post-patchelf repairs for the ChatGPT Desktop payload, plus the audits that keep
// them honest across version bumps.
//
// Two things go wrong when autoPatchelfHook is pointed at OpenAI's official .deb:
//
//   relocate  The bundled detect-libc reads only the first 2048 bytes of
//             /proc/self/exe to find PT_INTERP and decide glibc vs musl. A Nix
//             store interpreter path does not fit the original 27-byte slot, so
//             patchelf parks the string at the end of a 315 MB binary, where the
//             detector cannot see it. Detection then falls through to
//             process.report.getReport(), which traps with SIGILL inside Electron
//             and kills the app a few seconds after launch. This moves the string
//             back into patchelf's own padding, without changing the file length.
//
//   audit-init  patchelf can rewrite DT_INIT to an offset inside the ELF header
//             (0x25c on libvips-cpp.so.8.18.3), and dlopen then segfaults in
//             _dl_init. Nothing about that is visible to ldd, so it needs its own
//             check.
//
// Everything here is deliberately fail-closed: an unexpected payload shape is an
// error, never a silent skip.

'use strict';

const fs = require('fs');
const path = require('path');

// detect-libc/lib/filesystem.js: `const MAX_LENGTH = 2048;`
const DETECT_LIBC_SCAN_SIZE = 2048;

// patchelf fills the space it reserves with NUL, 'X' or 'Z' depending on what it
// is padding; anything else in that range belongs to somebody.
const PATCHELF_FILL_BYTES = new Set([0x00, 0x58, 0x5a]);

const PT_LOAD = 1;
const PT_DYNAMIC = 2;
const PT_INTERP = 3;
const PF_X = 0x1;

const SHT_PROGBITS = 1;
const SHT_NOBITS = 8;
const SHF_EXECINSTR = 0x4n;

const DT_NULL = 0;
const DT_INIT = 12;

const PHDR_ENTRY_SIZE = 56;
const SHDR_ENTRY_SIZE = 64;
const DYN_ENTRY_SIZE = 16;

function fail(message) {
  process.stderr.write(`chatgpt-elf-fixups: ${message}\n`);
  process.exit(1);
}

function readAt(fd, length, position) {
  const buffer = Buffer.alloc(length);
  let filled = 0;
  while (filled < length) {
    const read = fs.readSync(fd, buffer, filled, length - filled, position + filled);
    if (read === 0) {
      break;
    }
    filled += read;
  }
  return buffer.subarray(0, filled);
}

// Reads only the headers, never the payload: these binaries are hundreds of
// megabytes and nothing here needs their contents.
function parseElf(fd, size) {
  const ident = readAt(fd, 64, 0);
  if (ident.length < 64) {
    return null;
  }
  if (ident.readUInt32BE(0) !== 0x7f454c46) {
    return null;
  }
  // 64-bit little-endian only; every other class is left to whoever owns it.
  if (ident.readUInt8(4) !== 2 || ident.readUInt8(5) !== 1) {
    return null;
  }

  const programOffset = Number(ident.readBigUInt64LE(0x20));
  const sectionOffset = Number(ident.readBigUInt64LE(0x28));
  const programEntrySize = ident.readUInt16LE(0x36);
  const programCount = ident.readUInt16LE(0x38);
  const sectionEntrySize = ident.readUInt16LE(0x3a);
  const sectionCount = ident.readUInt16LE(0x3c);
  const sectionNameIndex = ident.readUInt16LE(0x3e);

  if (programCount > 0 && programEntrySize !== PHDR_ENTRY_SIZE) {
    fail(`unexpected e_phentsize ${programEntrySize}`);
  }
  if (sectionCount > 0 && sectionEntrySize !== SHDR_ENTRY_SIZE) {
    fail(`unexpected e_shentsize ${sectionEntrySize}`);
  }

  // Some vendored prebuilds carry header tables that point past EOF. Those are
  // unreadable rather than malformed for our purposes: parse what is there and
  // let each command decide whether it can work without the rest.
  const programs = [];
  const programTableBytes = programCount * PHDR_ENTRY_SIZE;
  const table = readAt(fd, programTableBytes, programOffset);
  if (table.length === programTableBytes) {
    for (let index = 0; index < programCount; index += 1) {
      const at = index * PHDR_ENTRY_SIZE;
      programs.push({
        index,
        header: programOffset + at,
        type: table.readUInt32LE(at),
        flags: table.readUInt32LE(at + 4),
        offset: Number(table.readBigUInt64LE(at + 8)),
        vaddr: table.readBigUInt64LE(at + 16),
        paddr: table.readBigUInt64LE(at + 24),
        fileSize: Number(table.readBigUInt64LE(at + 32)),
        memSize: Number(table.readBigUInt64LE(at + 40)),
      });
    }
  }

  const sections = [];
  const sectionTableBytes = sectionCount * SHDR_ENTRY_SIZE;
  const sectionTable = readAt(fd, sectionTableBytes, sectionOffset);
  const sectionsReadable =
    sectionTable.length === sectionTableBytes && sectionNameIndex < sectionCount;
  if (sectionsReadable) {
    const nameTableAt = sectionNameIndex * SHDR_ENTRY_SIZE;
    const nameTableOffset = Number(sectionTable.readBigUInt64LE(nameTableAt + 24));
    const nameTableSize = Number(sectionTable.readBigUInt64LE(nameTableAt + 32));
    const names = readAt(fd, nameTableSize, nameTableOffset);
    for (let index = 0; index < sectionCount; index += 1) {
      const at = index * SHDR_ENTRY_SIZE;
      const nameStart = sectionTable.readUInt32LE(at);
      const nameEnd = names.indexOf(0, nameStart);
      sections.push({
        index,
        header: sectionOffset + at,
        name: names.subarray(nameStart, nameEnd < 0 ? undefined : nameEnd).toString(),
        type: sectionTable.readUInt32LE(at + 4),
        flags: sectionTable.readBigUInt64LE(at + 8),
        addr: sectionTable.readBigUInt64LE(at + 16),
        offset: Number(sectionTable.readBigUInt64LE(at + 24)),
        size: Number(sectionTable.readBigUInt64LE(at + 32)),
      });
    }
  }

  return {
    size,
    programs,
    sections,
    programsComplete: programs.length === programCount,
    sectionsComplete: sectionCount === 0 || sectionsReadable,
    programTable: { offset: programOffset, size: programTableBytes },
    sectionTable: { offset: sectionOffset, size: sectionTableBytes },
  };
}

function openElf(file, flags) {
  const fd = fs.openSync(file, flags);
  const elf = parseElf(fd, fs.fstatSync(fd).size);
  if (elf === null) {
    fs.closeSync(fd);
    return null;
  }
  return { fd, elf };
}

function interpreterOf(fd, elf) {
  const segment = elf.programs.find(({ type }) => type === PT_INTERP);
  if (segment === undefined) {
    fail('no PT_INTERP segment');
  }
  const raw = readAt(fd, segment.fileSize, segment.offset);
  return { segment, value: raw.toString().replace(/\0.*$/s, '') };
}

function overlaps(start, end, otherStart, otherSize) {
  return otherSize > 0 && start < otherStart + otherSize && otherStart < end;
}

// The only safe place for the interpreter string is padding patchelf itself
// reserved: mapped by exactly one PT_LOAD, claimed by no other header.
function findPaddingSlot(fd, elf, length) {
  const window = readAt(fd, Math.min(DETECT_LIBC_SCAN_SIZE, elf.size), 0);
  const first = elf.programTable.offset + elf.programTable.size;
  const last = window.length - length;

  for (let candidate = first; candidate <= last; candidate += 1) {
    const end = candidate + length;
    if (!window.subarray(candidate, end).every((byte) => PATCHELF_FILL_BYTES.has(byte))) {
      continue;
    }

    const loads = elf.programs.filter(
      (program) =>
        program.type === PT_LOAD &&
        candidate >= program.offset &&
        end <= program.offset + program.fileSize,
    );
    if (loads.length !== 1) {
      continue;
    }

    const claimed =
      elf.programs.some(
        (program) =>
          program !== loads[0] &&
          program.type !== PT_INTERP &&
          overlaps(candidate, end, program.offset, program.fileSize),
      ) ||
      elf.sections.some(
        (section) =>
          section.type !== SHT_NOBITS && overlaps(candidate, end, section.offset, section.size),
      ) ||
      overlaps(candidate, end, elf.sectionTable.offset, elf.sectionTable.size);
    if (claimed) {
      continue;
    }

    return { offset: candidate, load: loads[0] };
  }

  return null;
}

function writeU64(fd, value, position) {
  const buffer = Buffer.alloc(8);
  buffer.writeBigUInt64LE(BigInt(value));
  fs.writeSync(fd, buffer, 0, 8, position);
}

function relocate(file, expected) {
  const opened = openElf(file, 'r+');
  if (opened === null) {
    fail(`${file}: not a 64-bit little-endian ELF`);
  }
  const { fd, elf } = opened;

  try {
    if (!elf.programsComplete || !elf.sectionsComplete) {
      fail(`${file}: header tables extend past the end of the file`);
    }
    const { segment, value } = interpreterOf(fd, elf);
    if (value !== expected) {
      fail(`${file}: PT_INTERP is "${value}", expected "${expected}"`);
    }
    if (segment.offset + segment.fileSize <= DETECT_LIBC_SCAN_SIZE) {
      process.stdout.write(`${path.basename(file)}: PT_INTERP already at ${segment.offset}\n`);
      return;
    }

    const bytes = Buffer.from(`${expected}\0`, 'utf8');
    const slot = findPaddingSlot(fd, elf, bytes.length);
    if (slot === null) {
      fail(
        `${file}: no patchelf padding for ${bytes.length} bytes below ${DETECT_LIBC_SCAN_SIZE}; ` +
          'the payload layout changed and detect-libc will crash the app',
      );
    }

    const vaddr = slot.load.vaddr + BigInt(slot.offset - slot.load.offset);
    fs.writeSync(fd, bytes, 0, bytes.length, slot.offset);
    writeU64(fd, slot.offset, segment.header + 8); // p_offset
    writeU64(fd, vaddr, segment.header + 16); // p_vaddr
    writeU64(fd, vaddr, segment.header + 24); // p_paddr
    writeU64(fd, bytes.length, segment.header + 32); // p_filesz
    writeU64(fd, bytes.length, segment.header + 40); // p_memsz

    // Keep the section view consistent with the segment view. The loader ignores
    // section headers, but every other ELF tool believes them.
    const interp = elf.sections.find(({ name }) => name === '.interp');
    if (interp !== undefined) {
      writeU64(fd, vaddr, interp.header + 16); // sh_addr
      writeU64(fd, slot.offset, interp.header + 24); // sh_offset
      writeU64(fd, bytes.length, interp.header + 32); // sh_size
    }

    // The old copy at the tail is now unreferenced; leaving it costs nothing and
    // changing the file length would invalidate every offset in the file.
    process.stdout.write(
      `${path.basename(file)}: PT_INTERP ${segment.offset} -> ${slot.offset}\n`,
    );
  } finally {
    fs.closeSync(fd);
  }

  check(file, expected);
}

function check(file, expected) {
  const opened = openElf(file, 'r');
  if (opened === null) {
    fail(`${file}: not a 64-bit little-endian ELF`);
  }
  const { fd, elf } = opened;

  try {
    if (!elf.programsComplete) {
      fail(`${file}: program header table extends past the end of the file`);
    }
    const { segment, value } = interpreterOf(fd, elf);
    if (value !== expected) {
      fail(`${file}: PT_INTERP is "${value}", expected "${expected}"`);
    }
    const end = segment.offset + segment.fileSize;
    if (end > DETECT_LIBC_SCAN_SIZE) {
      fail(
        `${file}: PT_INTERP ends at ${end}, past detect-libc's ${DETECT_LIBC_SCAN_SIZE}-byte ` +
          'window; the app will crash with SIGILL a few seconds after launch',
      );
    }
    process.stdout.write(`${path.basename(file)}: PT_INTERP ok at ${segment.offset}\n`);
  } finally {
    fs.closeSync(fd);
  }
}

function initAddress(fd, elf) {
  const dynamic = elf.programs.find(({ type }) => type === PT_DYNAMIC);
  if (dynamic === undefined) {
    return null;
  }
  const entries = readAt(fd, dynamic.fileSize, dynamic.offset);
  for (let at = 0; at + DYN_ENTRY_SIZE <= entries.length; at += DYN_ENTRY_SIZE) {
    const tag = Number(entries.readBigUInt64LE(at));
    if (tag === DT_NULL) {
      break;
    }
    if (tag === DT_INIT) {
      return entries.readBigUInt64LE(at + 8);
    }
  }
  return null;
}

function auditInit(root) {
  const damaged = [];
  let inspected = 0;

  const walk = (directory) => {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const target = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        walk(target);
      } else if (entry.isFile()) {
        const opened = openElf(target, 'r');
        if (opened === null) {
          continue;
        }
        const { fd, elf } = opened;
        try {
          inspected += 1;
          const init = initAddress(fd, elf);
          if (init === null || init === 0n) {
            continue;
          }
          // DT_INIT must land in something the loader will actually execute.
          // Segments are too coarse to catch this: patchelf leaves the first
          // PT_LOAD executable and it covers the ELF header, so a DT_INIT of
          // 0x25c looks fine at segment granularity. Sections are what tell the
          // difference, so only fall back to segments when they are unreadable.
          const executable = elf.sectionsComplete
            ? elf.sections.some(
                (section) =>
                  section.type === SHT_PROGBITS &&
                  (section.flags & SHF_EXECINSTR) !== 0n &&
                  init >= section.addr &&
                  init < section.addr + BigInt(section.size),
              )
            : elf.programs.some(
                (program) =>
                  program.type === PT_LOAD &&
                  (program.flags & PF_X) !== 0 &&
                  init >= program.vaddr &&
                  init < program.vaddr + BigInt(program.memSize),
              );
          if (!executable) {
            damaged.push(`${path.relative(root, target)} (DT_INIT 0x${init.toString(16)})`);
          }
        } finally {
          fs.closeSync(fd);
        }
      }
    }
  };

  walk(root);

  if (damaged.length > 0) {
    fail(
      `DT_INIT points outside every executable section in:\n  ${damaged.join('\n  ')}\n` +
        'patchelf corrupted these; dlopen will segfault in _dl_init',
    );
  }
  process.stdout.write(`audit-init: ${inspected} ELF objects, all DT_INIT sound\n`);
}

function main(argv) {
  const [command, ...rest] = argv;
  switch (command) {
    case 'relocate':
      if (rest.length !== 2) {
        fail('usage: relocate <elf> <expected-interpreter>');
      }
      relocate(rest[0], rest[1]);
      break;
    case 'check':
      if (rest.length !== 2) {
        fail('usage: check <elf> <expected-interpreter>');
      }
      check(rest[0], rest[1]);
      break;
    case 'audit-init':
      if (rest.length !== 1) {
        fail('usage: audit-init <directory>');
      }
      auditInit(rest[0]);
      break;
    default:
      fail('usage: chatgpt-elf-fixups.cjs relocate|check|audit-init ...');
  }
}

main(process.argv.slice(2));
