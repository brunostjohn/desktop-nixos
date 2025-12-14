{ pkgs, ... }:

{
  hardware.steam-hardware.enable = true;

  programs.gamescope.enable = true;

  programs.gamemode.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    platformOptimizations.enable = true;
    package = pkgs.steam.override {
      extraPkgs = (pkgs: with pkgs; [ gamemode apple-cursor ]);
    };
  };
}
