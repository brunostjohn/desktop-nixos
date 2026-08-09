{ pkgs, ... }:

{
  hardware.steam-hardware.enable = true;

  programs.gamescope.enable = true;

  programs.steam = {
    enable = true;

    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;

    platformOptimizations.enable = true;

    extraCompatPackages = [ pkgs.proton-ge-bin ];

    extraPackages = with pkgs; [
      gamemode
      gamescope
      gamescope-wsi
      mangohud
      apple-cursor
    ];

    extest.enable = true;
    protontricks.enable = true;
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        inhibit_screensaver = 1;
      };

      custom = {
        start =
          "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
        end = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced";
      };
    };
  };
}
