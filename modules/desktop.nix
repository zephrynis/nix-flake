{ pkgs, ... }:

{
  # System-side requirements of illogical-flake (the HM module does the rest)
  programs.hyprland.enable = true;
  services.geoclue2.enable = true; # QtPositioning — weather / night light widgets

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # file pickers etc.

  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;

  fonts.packages = with pkgs; [
    # named by the illogical-flake README
    rubik
    nerd-fonts.ubuntu
    nerd-fonts.jetbrains-mono
    material-symbols
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
