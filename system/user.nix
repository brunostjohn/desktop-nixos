{ pkgs, ... }:

{
  users.users.brunostjohn.shell = pkgs.zsh;

  users.users.brunostjohn = {
    isNormalUser = true;
    description = "Bruno St John";
    extraGroups = [ "networkmanager" "wheel" "docker" "gamemode" ];
    packages = [ ];
  };

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "brunostjohn";
}
