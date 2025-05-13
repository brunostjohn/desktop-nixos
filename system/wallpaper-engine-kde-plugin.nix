{ pkgs, ... }:

let glslang-submodule = import ./glslang-submodule.nix { inherit pkgs; };
in with pkgs;
stdenv.mkDerivation rec {
  pname = "wallpaperEngineKde";
  version = "91d8e25c0c94b4919f3d110c1f22727932240b3c";
  src = fetchFromGitHub {
    owner = "Jelgnum";
    repo = "wallpaper-engine-kde-plugin";
    rev = version;
    hash = "sha256-ff3U/TXr9umQeVHiqfEy38Wau5rJuMeJ3G/CZ9VE++g=";
    fetchSubmodules = true;
  };
  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    glslang-submodule
    pkg-config
    gst_all_1.gst-libav
    shaderc
  ];
  buildInputs = [ mpv lz4 vulkan-headers vulkan-tools vulkan-loader ]
    ++ (with libsForQt5;
      with qt5; [
        plasma-framework
        qtwebsockets
        qtwebchannel
        qtx11extras
        qtdeclarative
      ])
    ++ [ (python3.withPackages (python-pkgs: [ python-pkgs.websockets ])) ];
  cmakeFlags = [ "-DUSE_PLASMAPKG=ON" ];
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
