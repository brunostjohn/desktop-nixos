{ pkgs, config, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia.package = let
    gpl_symbols_linux_615_patch = pkgs.fetchpatch {
      url =
        "https://github.com/CachyOS/kernel-patches/raw/914aea4298e3744beddad09f3d2773d71839b182/6.15/misc/nvidia/0003-Workaround-nv_vm_flags_-calling-GPL-only-code.patch";
      hash = "sha256-YOTAvONchPPSVDP9eJ9236pAPtxYK5nAePNtm2dlvb4=";
      stripLen = 1;
      extraPrefix = "kernel/";
    };
  in config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "580.76.05";
    sha256_64bit = "sha256-IZvmNrYJMbAhsujB4O/4hzY8cx+KlAyqh7zAVNBdl/0=";
    sha256_aarch64 = "sha256-NL2DswzVWQQMVM092NmfImqKbTk9VRgLL8xf4QEvGAQ=";
    openSha256 = "sha256-xEPJ9nskN1kISnSbfBigVaO6Mw03wyHebqQOQmUg/eQ=";
    settingsSha256 = "sha256-ll7HD7dVPHKUyp5+zvLeNqAb6hCpxfwuSyi+SAXapoQ=";
    persistencedSha256 = "sha256-bs3bUi8LgBu05uTzpn2ugcNYgR5rzWEPaTlgm0TIpHY=";

    patches = [ gpl_symbols_linux_615_patch ];
  };

  hardware.nvidia.open = true;
  boot.initrd.kernelModules = [ "nvidia" ];
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.nvidiaSettings = false;
}
