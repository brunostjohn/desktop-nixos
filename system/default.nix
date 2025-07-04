{ pkgs, inputs, lib, config, ... }:

let vulkan-hdr-layer = import ./vulkan-hdr-layer.nix { inherit pkgs; };
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
  ];

  nixpkgs.config.permittedInsecurePackages = [ "electron-33.4.11" ];

  services.fstrim.enable = true;

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

  environment.systemPackages =
    let nvidiaEnabled = lib.elem "nvidia" config.services.xserver.videoDrivers;
    in (with pkgs; [
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
      qt6.qtwebengine
      (python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))
    ]) ++ lib.optionals nvidiaEnabled [
      (config.hardware.nvidia.package.settings.overrideAttrs (oldAttrs: {
        buildInputs = oldAttrs.buildInputs ++ [ pkgs.vulkan-headers ];
      }))
    ];

  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  services.flatpak.enable = true;
  programs.java.enable = true;

  nixos.pkgs = { wallpaper-engine-kde-plugin.enable = true; };

  system.stateVersion = "24.11";
}
