{ ... }:

{
  programs.plasma = {
    enable = true;
    workspace = {
      clickItemTo = "select";
      lookAndFeel = "org.kde.breezedark.desktop";
      cursor.theme = "macOS";
      # iconTheme = "Papirus-Dark";
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
      "kwinrc"."Effect-better-blur-dx"."WindowClasses" = "zen-twilight\ncom.mitchellh.ghostty";
    };
  };
}
