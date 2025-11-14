{ pkgs, config, lib, ... }:

let
  nvidia-package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "580.105.08";
    sha256_64bit = "sha256-2cboGIZy8+t03QTPpp3VhHn6HQFiyMKMjRdiV2MpNHU=";
    sha256_aarch64 = lib.fakeHash;
    openSha256 = "sha256-FGmMt3ShQrw4q6wsk8DSvm96ie5yELoDFYinSlGZcwQ=";
    settingsSha256 = lib.fakeHash;
    persistencedSha256 = lib.fakeHash;
  };
in {
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
    enable32Bit = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia.package = nvidia-package;

  hardware.nvidia.open = true;
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = [ nvidia-package ];
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker.daemon.settings.features.cdi = true;
  hardware.nvidia.modesetting.enable = true;
  hardware.nvidia.nvidiaSettings = false;
}
