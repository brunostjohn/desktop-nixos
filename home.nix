{ pkgs, inputs, ... }: {
  home = {
    packages = with pkgs; [
      fastfetch
      code-cursor
      nixfmt-classic
      nixd
      gh
      ghostty
      zip
      xz
      unzip
      p7zip
      apple-cursor
      vesktop
      caprine-bin
      signal-desktop
      prismlauncher
      htop
      protonup-qt
      protontricks
      lutris
      yt-dlp
      ffmpeg-full
      openboardview
      obs-studio
      okular
      kicad
      (heroic.override { extraPkgs = pkgs: with pkgs; [ gamescope gamemode ]; })
      bambu-studio
    ];

    username = "brunostjohn";
    homeDirectory = "/home/brunostjohn";
    stateVersion = "24.11";
  };
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "Bruno St John";
    userEmail = "brunost.john@icloud.com";
    extraConfig = {
      init.defaultBranch = "main";
      push = { autoSetupRemote = true; };
      credential.helper = "${
          pkgs.git.override { withLibsecret = true; }
        }/bin/git-credential-libsecret";
    };
  };
  programs.plasma = {
    enable = true;
    workspace = {
      clickItemTo = "select";
      lookAndFeel = "org.kde.breezedark.desktop";
      cursor.theme = "macOS";
      # iconTheme = "Papirus-Dark";
      wallpaper =
        "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Patak/contents/images/1080x1920.png";
    };
    configFile = {
      "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;
      "kwinrc"."org.kde.kdecoration2"."ButtonsOnLeft" = "SF";
      "kwinrc"."Desktops"."Number" = {
        value = 8;
        immutable = true;
      };
    };
  };
  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [ pkgs.firefoxpwa ];
    policies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true; # save webs for later reading
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = false;
    };
    profiles.brunostjohn = {
      extensions = with inputs.firefox-addons.packages.${pkgs.system}; [
        ublock-origin
        dearrow
        istilldontcareaboutcookies
        sponsorblock
      ];
      settings = {
        "browser.download.useDownloadDir" = false;
        "browser.disableResetPrompt" = true;
        "browser.download.panel.shown" = true;
        "browser.feeds.showFirstRunUI" = false;
        "browser.messaging-system.whatsNewPanel.enabled" = false;
        "browser.rights.3.shown" = true;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "browser.startup.homepage_override.mstone" = "ignore";
        "browser.uitour.enabled" = false;
        "startup.homepage_override_url" = "";
        "trailhead.firstrun.didSeeAboutWelcome" = true;
        "browser.bookmarks.restore_default_bookmarks" = false;
        "browser.bookmarks.addedImportButton" = true;
        "app.shield.optoutstudies.enabled" = false;
        "browser.discovery.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
        "datareporting.healthreport.service.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "datareporting.sessions.current.clean" = true;
        "devtools.onboarding.telemetry.logged" = false;
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;
        "toolkit.telemetry.hybridContent.enabled" = false;
        "toolkit.telemetry.newProfilePing.enabled" = false;
        "toolkit.telemetry.prompted" = 2;
        "toolkit.telemetry.rejected" = true;
        "toolkit.telemetry.reportingpolicy.firstRun" = false;
        "toolkit.telemetry.server" = "";
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.unifiedIsOptIn" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "privacy.trackingprotection.enabled" = true;
        "zen.widget.linux.transparency" = true;
        "zen.theme.gradient.show-custom-colors" = true;
        "zen.view.grey-out-inactive-windows" = false;
      };
    };
  };
  xdg.mimeApps.defaultApplications = {
    "text/html" = [ "zen-beta.desktop" ];
    "text/xml" = [ "zen-beta.desktop" ];
    "text/svg" = [ "zen-beta.desktop" ];
    "x-scheme-handler/http" = [ "zen-beta.desktop" ];
    "x-scheme-handler/https" = [ "zen-beta.desktop" ];
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
      update = "sudo nixos-rebuild switch";
    };

    history.size = 10000;
    history.ignoreAllDups = true;
    history.path = "$HOME/.zsh_history";
    history.ignorePatterns = [ "rm *" "pkill *" "cp *" ];

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "fino-time";
    };
  };
}
