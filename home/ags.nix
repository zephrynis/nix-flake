{ config, pkgs, inputs, ... }:

{
  # AGS v3 - Aylur's GTK Shell with Astal (colorshell configuration)
  imports = [ inputs.ags.homeManagerModules.default ];
  
  programs.ags = {
    enable = true;
    
    # null = use ~/.config/ags (colorshell files are there)
    configDir = null;
    
    # Add Astal packages needed for colorshell
    extraPackages = with pkgs; [
      inputs.astal.packages.${pkgs.system}.astal3
      inputs.astal.packages.${pkgs.system}.apps
      inputs.astal.packages.${pkgs.system}.auth
      inputs.astal.packages.${pkgs.system}.battery
      inputs.astal.packages.${pkgs.system}.bluetooth
      inputs.astal.packages.${pkgs.system}.hyprland
      inputs.astal.packages.${pkgs.system}.mpris
      inputs.astal.packages.${pkgs.system}.network
      inputs.astal.packages.${pkgs.system}.notifd
      inputs.astal.packages.${pkgs.system}.powerprofiles
      inputs.astal.packages.${pkgs.system}.tray
      inputs.astal.packages.${pkgs.system}.wireplumber
      
      # Additional dependencies for colorshell
      nodejs_22
      pnpm
      glib
      glib.dev  # For glib-compile-resources
      gtk4
      libadwaita
      networkmanager
      bluez
      
      # Icon theme for fixing "network-wired-symbolic" warnings
      papirus-icon-theme
    ];
  };
  
  # Install icon theme system-wide to fix colorshell icon warnings
  home.packages = with pkgs; [
    papirus-icon-theme
  ];
}
