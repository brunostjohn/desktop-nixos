{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    substituters = [
      "https://attic.xuyh0120.win/lantian"
      "https://nix-gaming.cachix.org"
      "https://codex-desktop-linux.cachix.org"
    ];
    trusted-public-keys = [
      "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk="
    ];

    fallback = true;
    connect-timeout = 5;
    download-buffer-size = 268435456;
    narinfo-cache-negative-ttl = 60;
    http-connections = 50;
    max-substitution-jobs = 32;

    keep-derivations = true;

    min-free = 5368709120;
    max-free = 16106127360;

    trusted-users = [ "root" "@wheel" ];
    warn-dirty = false;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise.automatic = true;
  nix.optimise.dates = [ "03:45" ];

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    permittedInsecurePackages = [ "docker-28.5.2" "electron-39.8.10" ];
  };
}
