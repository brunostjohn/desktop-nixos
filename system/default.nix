{ pkgs, inputs, ... }:

{
  nixpkgs.overlays = [
    (final: _prev: {
      unstable = import inputs.nixpkgs-unstable {
        inherit (final.stdenv.hostPlatform) system;
        inherit (final) config;
      };
    })
  ];

  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./fonts.nix
    ./nix-setup.nix
    ./boot.nix
    ./performance.nix
    ./i18n.nix
    ./sound.nix
    ./gaming.nix
    ./user.nix
    ./networking.nix
    ./ssh.nix
    ./claude-desktop.nix
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nix-gaming.nixosModules.platformOptimizations
  ];

  services.fstrim.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/home" ];
  };

  services.smartd.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  hardware.bluetooth.enable = true;

  services.xserver.enable = false;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.printing.enable = true;

  programs.zsh.enable = true;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
    ];
  };

  environment.systemPackages = with pkgs; [
    gitFull
    wget
    lm_sensors
    mangohud
    kde-rounded-corners
    inputs.kwin-better-blur.packages.${stdenv.hostPlatform.system}.default
    vulkan-tools
    usbutils
    pciutils
    powertop
    apple-cursor
    bun
    corepack_24
    node-gyp
    node-pre-gyp
    pnpm
    pnpm-shell-completion
    nodejs_24
    tmux
  ];

  programs.alvr.enable = true;

  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  services.flatpak.enable = true;

  programs.java.enable = true;

  system.stateVersion = "25.05";
}
