{ pkgs, inputs, ... }:

{
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      inputs.apple-emoji.packages.${pkgs.system}.apple-emoji-linux
      noto-fonts
      noto-fonts-cjk-sans
      dejavu_fonts
      freefont_ttf
      gyre-fonts
      liberation_ttf
      unifont
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
    ];

    enableDefaultPackages = false;

    fontconfig = {
      defaultFonts = { emoji = [ "Apple Color Emoji" ]; };
      useEmbeddedBitmaps = true;
      localConf = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <alias>
            <family>serif</family>
            <prefer><family>Noto Serif</family></prefer>
          </alias>
          <alias>
            <family>sans-serif</family>
            <prefer><family>Noto Sans</family></prefer>
          </alias>
          <alias>
            <family>sans</family>
            <prefer><family>Noto Sans</family></prefer>
          </alias>
          <alias>
            <family>monospace</family>
            <prefer><family>Noto Mono</family></prefer>
          </alias>

          <match target="pattern">
                <test name="family"><string>monospace</string></test>
                <edit name="family" mode="append"><string>Apple Color Emoji</string></edit>
          </match>
          <match target="pattern">
                <test name="family"><string>sans</string></test>
                <edit name="family" mode="append"><string>Apple Color Emoji</string></edit>
          </match>

          <match target="pattern">
                <test name="family"><string>serif</string></test>
                <edit name="family" mode="append"><string>Apple Color Emoji</string></edit>
          </match>

          <match target="pattern">
                <test name="family"><string>sans-serif</string></test>
                <edit name="family" mode="append"><string>Apple Color Emoji</string></edit>
            </match> 

          <alias binding="strong">
            <family>emoji</family>
            <default><family>Apple Color Emoji</family></default>
          </alias>

          <alias binding="strong">
            <family>Noto Color Emoji</family>
            <prefer><family>Apple Color Emoji</family></prefer>
            <default><family>emoji</family></default>
          </alias>
          <alias binding="strong">
            <family>Segoe UI Emoji</family>
            <prefer><family>Apple Color Emoji</family></prefer>
            <default><family>emoji</family></default>
          </alias>
        </fontconfig>
      '';
    };
  };
}
