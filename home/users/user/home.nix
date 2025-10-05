{ config, pkgs, ... }:
{
  home.username = "user"; # set by flake variable in system configs; keep consistent
  home.homeDirectory = "/home/user";

  # Set once on first deploy; bump if you intentionally accept breaking changes
  home.stateVersion = "24.05";

  programs.home-manager.enable = true;

  programs.bash.enable = true;
  programs.starship = { enable = true; enableBashIntegration = true; };

  home.packages = with pkgs; [
    fastfetch
  ];
}
