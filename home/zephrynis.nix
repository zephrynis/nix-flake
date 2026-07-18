{ inputs, pkgs, ... }:

{
  imports = [ inputs.illogical-flake.homeManagerModules.default ];

  home.username = "zephrynis";
  home.homeDirectory = "/home/zephrynis";
  # Matches the release era of system.stateVersion; never change afterwards.
  home.stateVersion = "26.05";

  programs.illogical-impulse = {
    enable = true;
    # All default to true — listed for discoverability
    dotfiles = {
      fish.enable = true;
      kitty.enable = true;
      starship.enable = true;
    };
    # hyprland.plugins = [ ]; # listOf package, loaded via hyprland's plugin mechanism
  };

  programs.git = {
    enable = true;
    userName = "zephrynis";
    userEmail = "zephrynis.yt@gmail.com";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.vscode.enable = true;

  home.packages = with pkgs; [
    ripgrep
    fd
    fzf
    jq
    btop
    eza
    bat
    tree
    nixfmt-rfc-style
    nil # Nix LSP
  ];
}
