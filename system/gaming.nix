{ pkgs, ... }:

{
  hardware.steam-hardware.enable = true;

  programs.gamescope.enable = true;

  programs.steam = {
    enable = true;

    remotePlay.openFirewall = false;
    dedicatedServer.openFirewall = false;
    localNetworkGameTransfers.openFirewall = false;

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
        start = "${pkgs.systemd}/bin/systemctl --user start gamemode-performance-profile.service";
        end = "${pkgs.systemd}/bin/systemctl --user stop gamemode-performance-profile.service";
      };
    };
  };

  systemd.user.services.gamemode-performance-profile = {
    description = "Hold the performance power profile while GameMode is active";
    bindsTo = [ "gamemoded.service" ];
    partOf = [ "gamemoded.service" ];
    after = [ "gamemoded.service" ];

    serviceConfig = {
      Type = "simple";
      KillMode = "mixed";
      TimeoutStopSec = "5s";
      ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl launch --profile performance --reason GameMode-active --appid gamemode ${pkgs.coreutils}/bin/sleep infinity";
    };
  };
}
