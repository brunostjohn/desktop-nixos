{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.nix-gaming.nixosModules.pipewireLowLatency
    inputs.nix-gaming.nixosModules.platformOptimizations
  ];

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      efiSupport = true;
      devices = [ "nodev" ];
      extraEntries = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod search_fs_uuid
          insmod chain
          search --fs-uuid --set=root 3180d0c4-58fe-43a6-b4a0-21e7bd7801a4
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
  };
  networking.hostName = "catpaws";
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    substituters = [ "https://nix-gaming.cachix.org" ];
    trusted-public-keys = [
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
    ];
  };
  services.fstrim.enable = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 15d";
  };
  networking.networkmanager.enable = true;
  hardware.steam-hardware.enable = true;
  time.timeZone = "Europe/Dublin";

  i18n.defaultLocale = "en_IE.UTF-8";
  zramSwap = {
    enable = true;
    algorithm = "lz4";
  };
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      inputs.apple-emoji.packages.${pkgs.system}.apple-emoji-linux
      noto-fonts
      noto-fonts-cjk-sans
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
    ];
  };

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };

  hardware.bluetooth.enable = true;

  services.xserver.enable = false;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "pl";
    variant = "";
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [ nvidia-vaapi-driver ];
    enable32Bit = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "575.51.02";
    sha256_64bit = "sha256-XZ0N8ISmoAC8p28DrGHk/YN1rJsInJ2dZNL8O+Tuaa0=";
    sha256_aarch64 = "sha256-NNeQU9sPfH1sq3d5RUq1MWT6+7mTo1SpVfzabYSVMVI=";
    openSha256 = "sha256-NQg+QDm9Gt+5bapbUO96UFsPnz1hG1dtEwT/g/vKHkw=";
    settingsSha256 = "sha256-6n9mVkEL39wJj5FB1HBml7TTJhNAhS/j5hqpNGFQE4w=";
    persistencedSha256 = "sha256-dgmco+clEIY8bedxHC4wp+fH5JavTzyI1BI8BxoeJJI=";
  };
  boot.kernelPackages = pkgs.linuxPackages_cachyos-lto;
  hardware.nvidia.open = true;
  boot.initrd.kernelModules = [ "nvidia" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  boot.kernelParams = [
    "nvidia_drm.fbdev=1"
    "nvidia-drm.modeset=1"
    "module_blacklist=i915"
    "quiet"
    "splash"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
  ];
  boot.kernelModules = [ "ntsync" ];
  boot.plymouth = {
    enable = true;
    theme = "breeze";
  };
  boot.initrd.systemd.enable = true;
  console.keyMap = "pl2";

  services.printing.enable = true;

  programs.zsh.enable = true;
  users.users.brunostjohn.shell = pkgs.zsh;

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    lowLatency = {
      enable = true;
      quantum = 64;
      rate = 48000;
    };
  };

  users.users.brunostjohn = {
    isNormalUser = true;
    description = "Bruno St John";
    extraGroups = [ "networkmanager" "wheel" "docker" "gamemode" ];
    packages = [ ];
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia.modesetting.enable = true;

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "brunostjohn";

  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    wget
    lm_sensors
    mangohud
    (stdenv.mkDerivation rec {
      pname = "vulkan-hdr-layer";
      version = "63d2eec";

      src = (fetchFromGitHub {
        owner = "Zamundaaa";
        repo = "VK_hdr_layer";
        rev = "869199cd2746e7f69cf19955153080842b6dacfc";
        fetchSubmodules = true;
        hash = "sha256-xfVYI+Aajmnf3BTaY2Ysg5fyDO6SwDFGyU0L+F+E3is=";
      }).overrideAttrs (_: {
        GIT_CONFIG_COUNT = 1;
        GIT_CONFIG_KEY_0 = "url.https://github.com/.insteadOf";
        GIT_CONFIG_VALUE_0 = "git@github.com:";
      });

      nativeBuildInputs = [ vulkan-headers meson ninja pkg-config jq ];

      buildInputs = [
        vulkan-headers
        vulkan-loader
        vulkan-utility-libraries
        xorg.libX11
        xorg.libXrandr
        wayland-scanner
        xorg.libxcb
        wayland
      ];

      # Help vulkan-loader find the validation layers
      setupHook = writeText "setup-hook" ''
        addToSearchPath XDG_DATA_DIRS @out@/share
      '';

      meta = with lib; {
        description = "Layers providing Vulkan HDR";
        homepage = "https://github.com/Zamundaaa/VK_hdr_layer";
        platforms = platforms.linux;
        license = licenses.mit;
      };
    })
  ];

  networking.firewall.enable = false;
  system.stateVersion = "24.11";

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    platformOptimizations.enable = true;
  };
  programs.appimage.enable = true;
  programs.appimage.binfmt = true;
  services.flatpak.enable = true;
  programs.java.enable = true;

  programs.gamescope.enable = true;
  programs.gamemode.enable = true;
}
