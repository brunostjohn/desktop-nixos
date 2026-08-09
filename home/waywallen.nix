{
  config,
  lib,
  pkgs,
  ...
}:

let
  waywallen = pkgs.callPackage ../packages/waywallen.nix { };
  initialConfig = pkgs.writeText "waywallen-initial-config.toml" ''
    # NVIDIA cannot use the OWE web renderer's shared-texture path reliably.
    # Keep the old setup's quiet, 30 FPS behavior and render at 1440p.
    [plugin.wescene-renderer]
    enable_audio = "false"
    fps = "30"
    resolution = "3"

    [plugin.weweb-renderer]
    enable_audio = "false"
    fps = "30"
    resolution = "3"
    shared_texture_enabled = "false"
  '';
in
{
  home.packages = [ waywallen ];

  # Seed the defaults once so the Waywallen UI can subsequently update its
  # own configuration instead of being pointed at an immutable store file.
  home.activation.waywallenInitialConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    waywallen_config_directory=${lib.escapeShellArg "${config.xdg.configHome}/waywallen"}
    waywallen_config_file="$waywallen_config_directory/config.toml"
    if [[ ! -e "$waywallen_config_file" ]]; then
      run ${pkgs.coreutils}/bin/mkdir -p "$waywallen_config_directory"
      run ${pkgs.coreutils}/bin/install -m 0600 ${initialConfig} "$waywallen_config_file"
    fi
    unset waywallen_config_directory waywallen_config_file
  '';

  programs.plasma.workspace.wallpaperCustomPlugin = {
    plugin = "org.waywallen.kde";
    config.General = {
      DisplayName = "";
      ShowDiagnostics = false;
      MouseForward = true;
      AccentColorFromWallpaper = false;
    };
  };

  systemd.user.services.waywallen = {
    Unit = {
      Description = "Waywallen dynamic wallpaper daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${waywallen}/bin/waywallen --no-ui --plugin ${waywallen}/share/waywallen";
      Restart = "on-failure";
      RestartSec = 3;
      TimeoutStopSec = 10;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
