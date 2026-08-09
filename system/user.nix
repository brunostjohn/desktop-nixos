{ pkgs, ... }:

{
  users.users.brunostjohn.shell = pkgs.zsh;

  users.users.brunostjohn = {
    isNormalUser = true;
    description = "Bruno St John";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "gamemode"
    ];
    packages = [ ];
  };

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "brunostjohn";

  security.sudo.extraRules = [
    {
      users = [ "brunostjohn" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
