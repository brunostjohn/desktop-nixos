{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    substituters = [
      "https://nix-gaming.cachix.org"
      "https://codex-desktop-linux.cachix.org"
    ];
    trusted-public-keys = [
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk="
    ];

    fallback = false;
    connect-timeout = 5;
    download-attempts = 3;
    download-buffer-size = 268435456;
    narinfo-cache-negative-ttl = 60;
    http-connections = 50;
    max-substitution-jobs = 32;

    keep-derivations = true;

    min-free = 5368709120;
    max-free = 16106127360;

    require-sigs = true;
    trusted-users = [
      "root"
      "@wheel"
    ];
    warn-dirty = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise.automatic = true;
  nix.optimise.dates = [ "03:45" ];

  nixpkgs.config.allowUnfree = true;
}
