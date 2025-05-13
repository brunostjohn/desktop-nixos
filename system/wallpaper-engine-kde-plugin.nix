{ config, lib, pkgs, ... }:

let wallpaper-engine-kde-plugin = import ./wpe-build.nix { inherit pkgs; };
in {
  options.nixos = {
    pkgs.wallpaper-engine-kde-plugin = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = "Enable wallpaper-engine-kde-plugin.";
      };
    };
  };

  config = lib.mkIf (config.nixos.pkgs.wallpaper-engine-kde-plugin.enable) {
    environment.systemPackages = with pkgs; [
      wallpaper-engine-kde-plugin
      kdePackages.qtwebsockets
      kdePackages.qtwebchannel
      kdePackages.qtmultimedia
      kdePackages.qtwebengine
      (python3.withPackages (python-pkgs: [ python-pkgs.websockets ]))
    ];

    system.activationScripts = {
      wallpaper-engine-kde-plugin.text = ''
        wallpaperenginetarget=/share/plasma/wallpapers/com.github.catsout.wallpaperEngineKde
        mkdir -p /home/brunostjohn/.local/share/plasma/wallpapers
        chown -R brunostjohn:users /home/brunostjohn/.local/share/plasma
        ln -sf ${wallpaper-engine-kde-plugin}/$wallpaperenginetarget /home/brunostjohn/.local/$wallpaperenginetarget
      '';
    };
  };
}
