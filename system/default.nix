{ pkgs, inputs, lib, ... }:

let
  vulkan-hdr-layer = import ./vulkan-hdr-layer.nix { inherit pkgs; };
  kernel = pkgs.linuxPackages_cachyos-lto.kernel;
in {
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ./fonts.nix
    ./nix-setup.nix
    ./boot.nix
    ./i18n.nix
    ./sound.nix
    ./gaming.nix
    ./user.nix
    ./networking.nix
    ./wallpaper-engine-kde-plugin.nix
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nix-gaming.nixosModules.platformOptimizations
    inputs.ucodenix.nixosModules.default
  ];

  nixpkgs.config.permittedInsecurePackages = [ "electron-33.4.11" ];

  services.fstrim.enable = true;

  services.ucodenix = {
    enable = true;
    cpuModelId = "00B40F40";
  };

  zramSwap = {
    enable = true;
    algorithm = "lz4";
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

  system.modulesTree = [ (lib.getOutput "modules" kernel) ];

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      zlib
      fuse3
      icu
      zlib
      nss
      openssl
      curl
      expat
    ];
  };

  environment.systemPackages = with pkgs; [
    git
    wget
    lm_sensors
    mangohud
    kde-rounded-corners
    inputs.kwin-force-blur.packages.${system}.default
    vulkan-hdr-layer
    qt6.qtwebsockets
    qt6.qtmultimedia
    nixpkgs-fmt
    proton-cachyos_x86_64_v4
    qt6.qtwebengine
    usbutils
    pciutils
    powertop
    apple-cursor
    (python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))
  ];

  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  services.flatpak.enable = true;
  programs.java.enable = true;

  nixos.pkgs = { wallpaper-engine-kde-plugin.enable = true; };

  system.stateVersion = "25.05";
}
