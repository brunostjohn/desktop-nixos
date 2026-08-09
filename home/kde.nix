{ ... }:

{
  programs.plasma = {
    enable = true;
    workspace = {
      clickItemTo = "select";
      lookAndFeel = "org.kde.breezedark.desktop";
      cursor.theme = "macOS";
      # iconTheme = "Papirus-Dark";

      wallpaperCustomPlugin = {
        plugin = "com.github.catsout.wallpaperEngineKde";
        config.General = {
          SteamLibraryPath = "file:///home/brunostjohn/.local/share/Steam";
          WallpaperWorkShopId = "3120519113";
          WallpaperSource =
            "file:///home/brunostjohn/.local/share/Steam/steamapps/workshop/content/431960/3120519113/scene.json+scene";

          DisplayMode = 1;
          PauseMode = 4;
          PauseFilterByScreen = true;
          Fps = 30;
          MuteAudio = true;
          VideoBackend = 0;
        };
      };
    };
    configFile = {
      "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
      "kwinrc"."org.kde.kdecoration2"."ButtonsOnLeft" = "SF";
      "kwinrc"."Desktops"."Number" = {
        value = 8;
        immutable = true;
      };

      "kwinrc"."Plugins"."blurEnabled" = false;
      "kwinrc"."Plugins"."better_blur_dxEnabled" = true;

      "kwinrc"."Effect-better-blur-dx"."BlurStrength" = 15;
      "kwinrc"."Effect-better-blur-dx"."NoiseStrength" = 5;
      "kwinrc"."Effect-better-blur-dx"."Brightness" = 100;
      "kwinrc"."Effect-better-blur-dx"."Saturation" = 150;
      "kwinrc"."Effect-better-blur-dx"."Contrast" = 100;
      "kwinrc"."Effect-better-blur-dx"."CornerRadius" = 5.0;
      "kwinrc"."Effect-better-blur-dx"."BlurMatching" = true;
      "kwinrc"."Effect-better-blur-dx"."BlurNonMatching" = false;
      "kwinrc"."Effect-better-blur-dx"."WindowClasses" =
        "zen-twilight\ncom.mitchellh.ghostty";
    };
  };
}
