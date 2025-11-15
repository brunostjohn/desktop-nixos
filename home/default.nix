{ pkgs, inputs, ... }:

let
  unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config = { allowUnfree = true; };
  };
in {
  imports = [ ./kde.nix ./zen.nix ./zsh.nix ./git.nix ];

  home = {
    file.".icons/default".source = "${pkgs.apple-cursor}/share/icons";
    packages = with pkgs; [
      fastfetch
      kubectl
      kubectl-cnpg
      krew
      lens
      unstable.code-cursor
      bat
      nixfmt-classic
      nixd
      gh
      ghostty
      zip
      xz
      unzip
      p7zip
      apple-cursor
      caprine-bin
      signal-desktop
      prismlauncher
      htop
      protonup-qt
      protontricks
      popsicle
      lutris
      yt-dlp
      ffmpeg-full
      openboardview
      obs-studio
      kdePackages.okular
      gparted
      kicad
      (heroic.override { extraPkgs = pkgs: with pkgs; [ gamescope gamemode ]; })
      bambu-studio
      pokeget-rs
      linux-wallpaperengine
      discord
      unstable.lmstudio
      llama-cpp
    ];

    username = "brunostjohn";
    homeDirectory = "/home/brunostjohn";
    stateVersion = "25.05";
  };
  programs.home-manager.enable = true;
}
