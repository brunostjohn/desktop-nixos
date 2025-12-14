{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Bruno St John";
        email = "brunost.john@icloud.com";
      };

      init.defaultBranch = "main";
      push = { autoSetupRemote = true; };
      credential.helper = "${
          pkgs.git.override { withLibsecret = true; }
        }/bin/git-credential-libsecret";
    };
  };
}
