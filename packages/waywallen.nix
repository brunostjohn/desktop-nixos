{
  lib,
  stdenv,
  fetchurl,
  appimageTools,
  autoPatchelfHook,
  patchelf,
  p7zip,
  kdePackages,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  bzip2,
  cairo,
  cups,
  dav1d,
  dbus,
  expat,
  fontconfig,
  freetype,
  glib,
  libdrm,
  libgbm,
  libva,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  lz4,
  nspr,
  nss,
  pango,
  udev,
  vulkan-loader,
  zlib,
}:

let
  version = "0.3.2";

  displayVersion = "0.3.1";

  appImage = fetchurl {
    url = "https://github.com/waywallen/waywallen/releases/download/v${version}/waywallen-${version}-x86_64.AppImage";
    hash = "sha256-vUxfSaIjHqUD5aCXJIHlh0cmhtphP3NVNo1SQ5vaE3E=";
  };

  appImageContents = appimageTools.extractType2 {
    pname = "waywallen";
    inherit version;
    src = appImage;
  };

  sceneRendererSystemLibraryPath = lib.makeLibraryPath [
    fontconfig
    freetype
    libdrm
    libgbm
    lz4
    stdenv.cc.cc.lib
    vulkan-loader
    zlib
  ];

  ffmpeg7Libraries = stdenv.mkDerivation {
    pname = "waywallen-ffmpeg7-runtime";
    inherit version;

    nativeBuildInputs = [ autoPatchelfHook ];
    buildInputs = [
      bzip2
      dav1d
      libdrm
      libva
      stdenv.cc.cc.lib
      zlib
    ];
    runtimeDependencies = [
      libdrm
      zlib
    ];

    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/lib"
      for library in \
        libavcodec.so.61 \
        libavformat.so.61 \
        libavutil.so.59 \
        libiconv.so.2 \
        libswresample.so.5 \
        libswscale.so.8
      do
        cp "${appImageContents}/usr/lib/$library" "$out/lib/"
      done
      chmod u+w "$out/lib"/*
      runHook postInstall
    '';
  };

  kdeDisplay = stdenv.mkDerivation {
    pname = "waywallen-kde-display";
    version = displayVersion;
    dontWrapQtApps = true;

    src = fetchurl {
      url = "https://github.com/waywallen/waywallen-display/releases/download/v${displayVersion}/waywallen-kde-${displayVersion}-x86_64-embed.zip";
      hash = "sha256-6eb/4kRBMjIRYBvMK1XKGB33x7OSqyLKFrgBiFjYY6s=";
    };

    nativeBuildInputs = [
      autoPatchelfHook
      p7zip
    ];

    buildInputs = [
      kdePackages.qtbase
      kdePackages.qtdeclarative
      stdenv.cc.cc.lib
    ];

    unpackPhase = ''
      runHook preUnpack
      7z x "$src"
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/plasma/wallpapers"
      cp -R org.waywallen.kde "$out/share/plasma/wallpapers/"
      runHook postInstall
    '';
  };

  openWallpaperEngine = stdenv.mkDerivation {
    pname = "waywallen-open-wallpaper-engine";
    version = "0.2.3";

    src = fetchurl {
      url = "https://github.com/waywallen/open-wallpaper-engine/releases/download/v0.2.3/org.waywallen.open-wallpaper-engine-0.2.3-linux-x86_64.zip";
      hash = "sha256-oRM6aFs5XbbmD5rKaYARs5QNYul9TyFwl1w1qjQvMpo=";
    };

    nativeBuildInputs = [
      autoPatchelfHook
      p7zip
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
      glib
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
      lz4
      nspr
      nss
      pango
      stdenv.cc.cc.lib
      udev
      vulkan-loader
      zlib
    ];

    runtimeDependencies = [
      libdrm
      zlib
    ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall
      pluginDirectory="$out/share/waywallen/plugins/org.waywallen.open-wallpaper-engine"
      mkdir -p "$pluginDirectory"
      7z x "$src" -o"$pluginDirectory"
      chmod +x \
        "$pluginDirectory/bin/waywallen-wescene-renderer" \
        "$pluginDirectory/bin/weweb/waywallen-weweb-renderer" \
        "$pluginDirectory/bin/weweb/chrome-sandbox"
      runHook postInstall
    '';

    preFixup = ''
      addAutoPatchelfSearchPath ${ffmpeg7Libraries}/lib
    '';
  };
in
appimageTools.wrapType2 {
  pname = "waywallen";
  inherit version;
  src = appImage;

  extraInstallCommands = ''
    install -Dm444 \
      ${appImageContents}/usr/share/applications/org.waywallen.waywallen.desktop \
      "$out/share/applications/org.waywallen.waywallen.desktop"
    install -Dm444 \
      ${appImageContents}/usr/share/icons/hicolor/scalable/apps/org.waywallen.waywallen.svg \
      "$out/share/icons/hicolor/scalable/apps/org.waywallen.waywallen.svg"
    install -Dm444 \
      ${appImageContents}/usr/share/metainfo/org.waywallen.waywallen.metainfo.xml \
      "$out/share/metainfo/org.waywallen.waywallen.metainfo.xml"

    mkdir -p "$out/share/plasma" "$out/share/waywallen"
    cp -R ${kdeDisplay}/share/plasma/wallpapers "$out/share/plasma/"
    cp -R ${openWallpaperEngine}/share/waywallen/plugins "$out/share/waywallen/"

    sceneRenderer="$out/share/waywallen/plugins/org.waywallen.open-wallpaper-engine/bin/waywallen-wescene-renderer"
    chmod u+w "$sceneRenderer"
    ${patchelf}/bin/patchelf --force-rpath --set-rpath \
      ${ffmpeg7Libraries}/lib:${sceneRendererSystemLibraryPath} \
      "$sceneRenderer"
  '';

  extraPkgs = pkgs: [
    pkgs.libdrm
    pkgs.libgbm
    pkgs.vulkan-loader
    pkgs.wayland
  ];

  meta = {
    description = "Dynamic wallpaper manager with KDE and Wallpaper Engine support";
    homepage = "https://github.com/waywallen/waywallen";
    license = lib.licenses.mit;
    mainProgram = "waywallen";
    platforms = [ "x86_64-linux" ];
  };
}
