{
  time.timeZone = "Europe/Dublin";
  i18n.defaultLocale = "en_IE.UTF-8";

  i18n.extraLocales = [ "en_IE.UTF-8/UTF-8" "en_AU.UTF-8/UTF-8" ];

  i18n.extraLocaleSettings = {
    LANGUAGE = "en_IE.UTF-8";
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_AU.UTF-8";
    LC_COLLATE = "en_IE.UTF-8";
    LC_CTYPE = "en_IE.UTF-8";
  };

  services.xserver.xkb = {
    layout = "pl";
    variant = "";
  };

  console.keyMap = "pl2";
}
