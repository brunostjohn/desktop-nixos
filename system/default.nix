{ pkgs, inputs, ... }:

let vulkan-hdr-layer = import ./vulkan-hdr-layer.nix { inherit pkgs; };
in {
  nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlay ];

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
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nix-gaming.nixosModules.platformOptimizations
    inputs.ucodenix.nixosModules.default
  ];

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
    inputs.kwin-force-blur.packages.${stdenv.hostPlatform.system}.default
    vulkan-hdr-layer
    qt6.qtwebsockets
    qt6.qtmultimedia
    nixpkgs-fmt
    qt6.qtwebengine
    usbutils
    pciutils
    powertop
    apple-cursor
    kdePackages.wallpaper-engine-plugin
    (python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))
  ];

  programs.appimage.enable = true;
  programs.appimage.binfmt = true;

  services.flatpak.enable = true;

  programs.java.enable = true;

  system.stateVersion = "25.05";
}
