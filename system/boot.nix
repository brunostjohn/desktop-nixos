{ pkgs, ... }:

{
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      efiSupport = true;
      forceInstall = true;
      gfxmodeEfi = "3440x1440";
      gfxpayloadEfi = "3440x1440";
      devices = [ "/dev/disk/by-uuid/55E5-6FB8" ];
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

  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto;
  services.scx.enable = true;
  services.fwupd.enable = true;

  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;

  boot.kernelParams = [
    "nvidia_drm.fbdev=1"
    "nvidia-drm.modeset=1"
    "module_blacklist=i915"
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
    "preempt=full"
    "threadirqs"
    "microcode.amd_sha_check=off"
  ];
  boot.kernelModules = [ "ntsync" ];
  boot.plymouth = {
    enable = true;
    theme = "breeze";
  };
  boot.initrd.systemd.enable = true;
}
