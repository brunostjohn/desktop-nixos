{ pkgs, ... }:

let glslang-submodule = import ./glslang-submodule.nix { inherit pkgs; };
in with pkgs;
stdenv.mkDerivation rec {
  pname = "wallpaperEngineKde";
  version = "96230de92f1715d3ccc5b9d50906e6a73812a00a";
  src = fetchFromGitHub {
    owner = "Jelgnum";
    repo = "wallpaper-engine-kde-plugin";
    rev = version;
    hash = "sha256-vkWEGlDQpfJ3fAimJHZs+aX6dh/fLHSRy2tLEsgu/JU=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    glslang-submodule
    pkg-config
    gst_all_1.gst-libav
    shaderc
    ninja
  ];

  buildInputs = [ mpv lz4 vulkan-headers vulkan-tools vulkan-loader ]
    ++ (with kdePackages;
    with qt6Packages; [
      qtbase
      qt6.full
      kpackage
      kdeclarative
      libplasma
      qtwebsockets
      qtwebengine
      qtwebchannel
      qtmultimedia
      qtdeclarative
    ])
    ++ [ (python3.withPackages (python-pkgs: [ python-pkgs.websockets ])) ];

  cmakeFlags = [ "-DUSE_PLASMAPKG=OFF" ];
  dontWrapQtApps = true;

  postPatch = ''
    rm -rf src/backend_scene/third_party/glslang
    ln -s ${glslang-submodule.src} src/backend_scene/third_party/glslang
  '';
  #Optional informations
  meta = with lib; {
    description = "Wallpaper Engine KDE plasma plugin";
    homepage = "https://github.com/Jelgnum/wallpaper-engine-kde-plugin";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
