{ pkgs, ... }:

{
  imports = [ ./kde.nix ./zen.nix ./zsh.nix ./git.nix ];

  home = {
    packages = with pkgs; [
      fastfetch
      code-cursor
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
      lutris
      yt-dlp
      ffmpeg-full
      openboardview
      obs-studio
      kdePackages.okular
      kicad
      (heroic.override { extraPkgs = pkgs: with pkgs; [ gamescope gamemode ]; })
      bambu-studio
      pokeget-rs
      linux-wallpaperengine
      discord
    ];

    username = "brunostjohn";
    homeDirectory = "/home/brunostjohn";
    stateVersion = "24.11";
  };
  programs.home-manager.enable = true;
}
