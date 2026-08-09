{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initContent = ''
      alias cat=bat
      pokeget --hide-name random
    '';

    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
      "kernel-cache-check" =
        "nix run \"path://$HOME/NixOS%20Configuration#nixos-maintenance\" -- check \"$HOME/NixOS Configuration\"";
      rebuild = "nix run \"path://$HOME/NixOS%20Configuration#nixos-maintenance\" -- rebuild \"$HOME/NixOS Configuration\"";
      update = "nix run \"path://$HOME/NixOS%20Configuration#nixos-maintenance\" -- update \"$HOME/NixOS Configuration\"";
    };

    history.size = 10000;
    history.ignoreAllDups = true;
    history.path = "$HOME/.zsh_history";
    history.ignorePatterns = [
      "rm *"
      "pkill *"
      "cp *"
    ];

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "fino-time";
    };
  };
}
