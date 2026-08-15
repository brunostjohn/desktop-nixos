{ pkgs, ... }:

{
  imports = [
    ./ai.nix
    ./gaming.nix
    ./kde.nix
    ./waywallen.nix
    ./zen.nix
    ./zsh.nix
    ./git.nix
  ];

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
      nixfmt
      nixd
      gh
      btop-cuda
      ghostty
      zip
      xz
      unzip
      p7zip
      apple-cursor
      caprine-bin
      signal-desktop
      htop
      protonup-qt
      popsicle
      lutris
      umu-launcher
      yt-dlp
      ffmpeg-full
      openboardview
      obs-studio
      kdePackages.okular
      gparted
      jdk25
      (heroic.override {
        extraPkgs =
          pkgs: with pkgs; [
            gamescope
            gamemode
          ];
      })
      pokeget-rs
      discord
      unstable.lmstudio
      llama-cpp
    ];

    username = "brunostjohn";
    homeDirectory = "/home/brunostjohn";
    stateVersion = "25.05";
  };
  programs.home-manager.enable = true;

  programs.mangohud = {
    enable = true;
    settings = {
      fps = true;
      frametime = true;
      frame_timing = 1;
      gpu_stats = true;
      gpu_temp = true;
      gpu_power = true;
      gpu_load_change = true;
      cpu_stats = true;
      cpu_temp = true;
      cpu_load_change = true;
      vram = true;
      ram = true;
      frame_count = false;
      histogram = true;
      round_corners = 8;
      background_alpha = 0.4;
      font_size = 20;
      position = "top-left";
      toggle_hud = "Shift_R+F12";
      toggle_logging = "Shift_L+F2";
    };
  };
}
