{
  lib,
  stdenv,
  fetchurl,
  addDriverRunpath,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
  nodejs,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  graphite2,
  gtk3,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libusb1,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxcrypt-legacy,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxscrnsaver,
  libxtst,
  nspr,
  nss,
  openssl,
  pango,
  pipewire,
  pulseaudio,
  udev,
  vulkan-loader,
  wayland,
  xdg-utils,
  xz,
  zlib,
  zstd,
}:

let
  version = "26.810.52044";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_amd64.deb";
    hash = "sha256-cIoVobt24rt/DjduUUU5H6J3rTpkBXwdMlN73CobTm4=";
  };

  runtimeLibs = [
    libglvnd
    libnotify
    pipewire
    pulseaudio
    vulkan-loader
    wayland
  ];

  # The one library patchelf must not touch: rewriting it leaves DT_INIT pointing
  # into the ELF header, and dlopen then segfaults in _dl_init, taking out
  # require("sharp") and with it computer use, screenshots and OCR. Its own
  # $ORIGIN RUNPATH already resolves its siblings, so it needs nothing from us.
  preservedLibrary = "resources/cua_node/lib/node_modules/@img/sharp-libvips-linux-x64/lib/libvips-cpp.so";

  elfFixups = ./chatgpt-elf-fixups.cjs;
in
stdenv.mkDerivation {
  pname = "chatgpt-desktop";
  inherit version src;

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
    nodejs
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libusb1
    libx11
    libxcb
    libxcomposite
    libxcrypt-legacy
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxkbcommon
    libxrandr
    libxscrnsaver
    libxtst
    nspr
    nss
    openssl
    pango
    stdenv.cc.cc.lib
    udev
    xz
    zlib
    zstd
  ]
  ++ runtimeLibs;

  runtimeDependencies = runtimeLibs;

  dontWrapGApps = true;
  dontConfigure = true;
  dontBuild = true;

  # This is a prebuilt vendor payload; stripping it buys nothing and risks the
  # kind of damage the audits below exist to catch.
  dontStrip = true;

  # autoPatchelf is invoked by hand in postFixup, because one library has to be
  # kept out of its way and PT_INTERP has to be repaired once it has finished.
  # The hook would otherwise run last: runHook evaluates the postFixup attribute
  # before postFixupHooks (nixpkgs stdenv/setup).
  dontAutoPatchelf = true;

  autoPatchelfIgnoreMissingDeps = [
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    "libc.musl-x86_64.so.1"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar --extract --no-same-permissions --no-same-owner
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib"
    cp -r usr/lib/chatgpt "$out/lib/chatgpt"

    rm -f "$out/lib/chatgpt/codex-launcher"

    install -Dm444 usr/share/applications/chatgpt.desktop \
      "$out/share/applications/chatgpt.desktop"
    install -Dm444 usr/share/pixmaps/chatgpt.png \
      "$out/share/pixmaps/chatgpt.png"

    substituteInPlace "$out/share/applications/chatgpt.desktop" \
      --replace-fail "Exec=chatgpt" "Exec=$out/bin/chatgpt"

    runHook postInstall
  '';

  preFixup = ''
    makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}:${addDriverRunpath.driverLink}/lib" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}" \
      --set-default ALSA_PLUGIN_DIR "${pipewire}/lib/alsa-lib" \
      --set-default CODEX_CLI_PATH "$out/lib/chatgpt/resources/codex" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations" \
      --add-flags "--enable-wayland-ime=true" \
      --add-flags "--wayland-text-input-version=3"
  '';

  postFixup = ''
    preserved=("$out/lib/chatgpt/${preservedLibrary}".*)
    if [ ''${#preserved[@]} -ne 1 ] || [ ! -e "''${preserved[0]}" ]; then
      echo "expected exactly one ${baseNameOf preservedLibrary}.*, found: ''${preserved[*]}" >&2
      exit 1
    fi
    cp -p "''${preserved[0]}" "$NIX_BUILD_TOP/preserved-library.so"

    autoPatchelf -- "$out"

    # Restore the pristine copy over whatever patchelf made of it. It has to stay
    # in place for the pass above, or the sharp addon that links against it fails
    # to resolve and autoPatchelf aborts; by now that addon's RPATH records this
    # directory, so swapping the file back is enough.
    rm -f "''${preserved[0]}"
    cp -p "$NIX_BUILD_TOP/preserved-library.so" "''${preserved[0]}"

    tectonic="$out/lib/chatgpt/resources/plugins/openai-bundled/plugins/latex/bin/tectonic"
    if [ -e "$tectonic" ]; then
      mv "$tectonic" "$tectonic.orig"
      makeWrapper "${stdenv.cc.bintools.dynamicLinker}" "$tectonic" \
        --add-flags "--library-path ${
          lib.makeLibraryPath [
            graphite2
            stdenv.cc.cc.lib
          ]
        }" \
        --add-flags "--argv0 tectonic" \
        --add-flags "$tectonic.orig"
    fi

    # The bundled detect-libc reads only the first 2048 bytes of /proc/self/exe to
    # find PT_INTERP and pick a glibc or musl prebuild. A store interpreter path
    # does not fit the original slot, so patchelf parks it at the end of a 315 MB
    # binary; detection then falls through to process.report.getReport(), which
    # traps with SIGILL inside Electron and kills the app seconds after launch.
    node ${elfFixups} relocate \
      "$out/lib/chatgpt/ChatGPT" "${stdenv.cc.bintools.dynamicLinker}"
  '';

  # Both repairs above are invisible to ldd, and both would come back silently on
  # the next `nix run .#update-ai-desktops`. Fail the build instead.
  doInstallCheck = true;

  installCheckPhase = ''
    runHook preInstallCheck

    node ${elfFixups} check \
      "$out/lib/chatgpt/ChatGPT" "${stdenv.cc.bintools.dynamicLinker}"
    node ${elfFixups} audit-init "$out/lib/chatgpt"

    NODE_PATH="$out/lib/chatgpt/resources/cua_node/lib/node_modules" \
      "$out/lib/chatgpt/resources/cua_node/bin/node" \
      -e 'require("sharp"); require("@napi-rs/canvas")'

    runHook postInstallCheck
  '';

  meta = {
    description = "Official ChatGPT desktop app for Linux, bundling ChatGPT, Work, and Codex";
    homepage = "https://chatgpt.com/download";
    downloadPage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "chatgpt";
    platforms = [ "x86_64-linux" ];
  };
}
