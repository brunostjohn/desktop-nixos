{ pkgs, ... }:

{
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
}
