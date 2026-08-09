{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    settings = {
      user = {
        name = "Bruno St John";
        email = "brunost.john@icloud.com";
      };

      init.defaultBranch = "main";
      push = { autoSetupRemote = true; };
      credential.helper = "libsecret";
    };
  };
}
