{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  makeWrapper,
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
  gtk3,
  libayatana-appindicator,
  libcap_ng,
  libdrm,
  libgbm,
  libglvnd,
  libnotify,
  libsecret,
  libseccomp,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxtst,
  nspr,
  nss,
  pango,
  pipewire,
  pulseaudio,
  qemu_kvm,
  udev,
  util-linux,
  vulkan-loader,
  xdg-utils,
}:

let
  version = "1.30096.1";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256-CeQaIKW0fqDlvCJtT/+nevQ61FDHy/XmblbW5P1K0uk=";
  };

  runtimeLibs = [
    libayatana-appindicator
    libglvnd
    libnotify
    libsecret
    pipewire
    pulseaudio
    vulkan-loader
  ];
in
stdenv.mkDerivation {
  pname = "claude-desktop";
  inherit version src;

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
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
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxtst
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    udev
    libcap_ng
    libseccomp
    util-linux
  ]
  ++ runtimeLibs;

  runtimeDependencies = runtimeLibs;

  dontWrapGApps = true;
  dontConfigure = true;
  dontBuild = true;

  autoPatchelfIgnoreMissingDeps = [
    "libvulkan.so.1"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar --extract --no-same-permissions --no-same-owner
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib" "$out/share"
    cp -r usr/lib/claude-desktop "$out/lib/claude-desktop"

    cp -r usr/share/applications "$out/share/applications"
    cp -r usr/share/icons "$out/share/icons"

    substituteInPlace "$out/share/applications/com.anthropic.Claude.desktop" \
      --replace-fail "Exec=claude-desktop" "Exec=$out/bin/claude-desktop"

    runHook postInstall
  '';

  preFixup = ''
    makeWrapper "$out/lib/claude-desktop/claude-desktop" "$out/bin/claude-desktop" \
      "''${gappsWrapperArgs[@]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}:/run/opengl-driver/lib" \
      --prefix PATH : "${
        lib.makeBinPath [
          qemu_kvm
          xdg-utils
        ]
      }" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations" \
      --add-flags "--enable-wayland-ime=true"
  '';

  meta = {
    description = "Official Claude desktop app for Linux, bundling Chat, Cowork, and Claude Code";
    homepage = "https://claude.ai/download";
    downloadPage = "https://code.claude.com/docs/en/desktop-linux";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "claude-desktop";
    platforms = [ "x86_64-linux" ];
  };
}
