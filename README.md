# Catpaws NixOS configuration

This machine uses Chaotic-Nyx's signed CachyOS kernels. The normal boot is the
cached BORE/ThinLTO `znver4` kernel; GRUB also receives a cached generic LTS
rescue specialisation. NVIDIA's matching open modules and Waywallen are allowed
to build locally, but the maintenance commands refuse to compile either kernel.

## Safe maintenance commands

The zsh configuration provides:

- `kernel-cache-check`: prove every main and rescue kernel output is signed and
  present in the Nyx cache, then realise both kernels with local builds disabled.
- `rebuild`: run that check, build the complete current configuration, and
  install it for the next boot without changing the running system.
- `update`: update into a temporary lock file, cache-check and build the
  candidate, atomically replace `flake.lock`, and install it for the next boot.

`rebuild` and `update` refuse to run while `flake.nix` or `flake.lock` has staged
or unstaged edits. An update failure restores the original lock file. Reboot
when ready; do not garbage-collect the previous generation until both the normal
and `lts-rescue` entries have booted successfully.

## AI desktop apps

Claude Desktop and ChatGPT Desktop are repacked in-repo from the vendors'
official `.deb` releases (`packages/claude-desktop.nix`,
`packages/chatgpt-desktop.nix`); the Claude Code CLI comes from Nixpkgs. None of
them is a flake input, so `nix flake update` never churns them.

Run `nix run .#update-ai-desktops` to bump both pins from the upstream apt
indexes, or `--check` to report staleness without writing. Anthropic keeps every
published version, so that pin can sit indefinitely. OpenAI prunes its pool after
roughly one to two weeks, so a long-stale `chatgpt-desktop` pin will eventually
fail to fetch; that is what the bump is for.

Cowork's micro-VM needs the FHS paths and kernel module wired up in
`system/claude-desktop.nix`.

The ChatGPT payload needs two repairs after `autoPatchelfHook` has run, both in
`packages/chatgpt-elf-fixups.cjs`. Its bundled `detect-libc` reads only the first
2 KiB of `/proc/self/exe` to find `PT_INTERP`, and patchelf leaves that at the end
of a 315 MB binary, so libc detection falls through to
`process.report.getReport()` — which traps with `SIGILL` inside Electron and kills
the app seconds after launch; the interpreter string is moved back into patchelf's
own padding. Separately, patchelf corrupts `DT_INIT` in the bundled libvips, so
that one library is restored untouched or `require("sharp")` segfaults and takes
computer use, screenshots and OCR with it. Neither fault is visible to `ldd`, so
`installCheckPhase` re-checks both and loads `sharp` before the build is allowed
to succeed. A pin bump that trips those checks means the payload changed shape,
not that the checks are wrong. Build either app on its own with
`nix build .#chatgpt-desktop` / `.#claude-desktop`.

## Gaming notes

GameMode temporarily holds power-profiles-daemon's `performance` profile. LAVD
follows it through `--autopower` and the original profile returns when the last
GameMode client exits. Prism Launcher enables this for the launched Minecraft
Java process. Steam titles remain opt-in with `gamemoderun %command%` in their
per-game launch options.

NVIDIA descriptor heaps reduce D3D12 resource-binding overhead; they are not a
shader-cache feature. After confirming `VK_EXT_descriptor_heap` in `vulkaninfo`,
test a game under Proton Experimental with:

```text
VKD3D_CONFIG=descriptor_heap %command%
```

Keep this per-game because the vkd3d-proton implementation still has known
NVIDIA failure cases. Remove the option first if a game black-screens.

Leave Steam shader pre-caching and background processing enabled. Do not
regularly delete Steam or NVIDIA shader caches; driver upgrades may invalidate
them naturally. For a one-game diagnostic, use `DXVK_HUD=compiler %command%`.

Waywallen replaces the archived in-process Wallpaper Engine Plasma plugin. On
first launch, let it detect `~/.local/share/Steam` and select Workshop item
`3120519113`. Its service defaults to 1440p/30 FPS, muted audio, fullscreen
pause, and NVIDIA-safe web rendering.

## Boot repair checkpoint

The configuration corrects GRUB to use the ESP mounted at `/boot`, but it does
not modify or repair the existing FAT filesystem automatically. Before the first
bootloader installation:

1. Prepare and test NixOS live media. From live media, record `efibootmgr -v`
   and make both an image and file-level backup of the unmounted ESP identified
   by UUID `55E5-6FB8`.
2. Run `fsck.fat -n -v /dev/disk/by-uuid/55E5-6FB8` read-only.
3. If the known primary/backup boot-sector mismatch is the only issue, run
   interactive `fsck.fat -r -V` and copy the known-working primary boot sector
   to the backup. Never use automatic `-a` or `-y` repair.
4. Mount the ESP at `/boot`, then install with
   `sudo nixos-rebuild boot --install-bootloader --flake path:.#catpaws`.
5. Verify `/boot/EFI/NixOS-boot/grubx64.efi`, the NVRAM entry, normal NixOS,
   `lts-rescue`, the rollback generation, and Windows before removing stale
   `/boot/EFI/EFI` files or old NVRAM entries.

The ESP is only 1 GiB, so GRUB intentionally keeps two NixOS generations.

## Hardware follow-up

After normal and rescue boots are proven, update the NZXT N7 B650E BIOS manually
from 3.25 to 4.10. Back up settings/checksums first, then re-enable and verify
EXPO, ReBAR, boot order, and stability. BIOS flashing is deliberately outside
the automated configuration.

The host firewall is intentionally disabled because this machine relies on the
home-network perimeter. SSH remains key-only, but listening services—including
Steam Remote Play/transfers, ALVR, and Docker-published ports—are not filtered
per interface on the PC. Bind future `docker -p` or Compose ports to an
intentional address when they should not listen on every interface.

Monthly Btrfs scrubs can detect corruption on `/home`, but the filesystem has no
redundant device from which to repair it. Keep an external backup.
