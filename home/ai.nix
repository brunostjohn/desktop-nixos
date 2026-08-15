{ pkgs, ... }:

let
  claude-desktop = pkgs.callPackage ../packages/claude-desktop.nix { };
  chatgpt-desktop = pkgs.callPackage ../packages/chatgpt-desktop.nix { };
in
{
  home.packages = [
    pkgs.claude-code
    claude-desktop
    chatgpt-desktop
    pkgs.unstable.codex
  ];

  xdg.desktopEntries.claude-code-url-handler = {
    name = "Claude Code URL Handler";
    genericName = "Handle claude-cli:// deep links for Claude Code";
    exec = "${pkgs.claude-code}/bin/claude --handle-uri %u";
    type = "Application";
    noDisplay = true;
    mimeType = [ "x-scheme-handler/claude-cli" ];
  };
}
