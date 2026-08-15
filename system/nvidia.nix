{ pkgs, config, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.latest;

    open = true;
    modesetting.enable = true;
    nvidiaSettings = true;
    powerManagement.enable = true;
  };

  environment.sessionVariables = {
    KWIN_DRM_DISABLE_TRIPLE_BUFFERING = "0";
    __GL_SHADER_DISK_CACHE_SIZE = "4294967296";
  };

  services.lact.enable = true;

  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_drm"
  ];

  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker.daemon.settings.features.cdi = true;
}
