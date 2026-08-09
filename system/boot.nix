{ lib, pkgs, ... }:

{
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      forceInstall = false;
      configurationLimit = 2;
      gfxmodeEfi = "3440x1440";
      gfxpayloadEfi = "3440x1440";
      extraEntries = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod search_fs_uuid
          insmod chain
          search --fs-uuid --set=root D8E5-486A
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
  };

  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto-znver4;

  specialisation.lts-rescue.configuration = {
    system.nixos.tags = [ "lts-rescue" ];
    boot.kernelPackages = lib.mkForce pkgs.linuxPackages_cachyos-lts;
    hardware.nvidia.package = lib.mkForce pkgs.nvidia_cachyos-lts;
    hardware.nvidia.open = lib.mkForce true;
    services.scx.enable = lib.mkForce false;
    services.lact.enable = lib.mkForce false;
    boot.plymouth.enable = lib.mkForce false;
  };

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = [ "--autopower" ];
  };

  services.fwupd.enable = true;

  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

  boot.kernelParams = [
    "nvidia_drm.fbdev=1"
    "nvidia-drm.modeset=1"
    "quiet"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
    "zswap.enabled=0"
    "amd_pstate=active"
  ];
  boot.kernelModules = [ "ntsync" ];
  boot.plymouth = {
    enable = true;
    theme = "breeze";
  };
  boot.initrd.systemd.enable = true;
}
