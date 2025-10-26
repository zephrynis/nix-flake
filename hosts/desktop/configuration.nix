{ config, pkgs, ... }:

{
  # Desktop PC specific configuration
  
  networking.hostName = "desktop";

  # Users configuration
  users.users.yourusername = { # Change "yourusername" to your actual username
    isNormalUser = true;
    description = "Your Name"; # Change this
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    shell = pkgs.zsh; # or pkgs.bash
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Display manager and desktop environment / window manager
  services.xserver = {
    enable = true;
    
    # Display manager
    displayManager.gdm.enable = true;
    
    # Desktop environment (choose one, or comment all for a standalone WM)
    # desktopManager.gnome.enable = true;
    # desktopManager.plasma5.enable = true;
    
    # Window manager (uncomment if you want a standalone WM)
    # windowManager.i3.enable = true;
    # windowManager.bspwm.enable = true;
  };

  # Optional: Enable Wayland compositor
  # programs.hyprland = {
  #   enable = true;
  #   xwayland.enable = true;
  # };

  # Desktop-specific packages (gaming, streaming, etc.)
  environment.systemPackages = with pkgs; [
    # Add desktop-specific packages here
    # discord
    # steam
    # obs-studio
  ];

  # Gaming support (uncomment if needed)
  # programs.steam.enable = true;
  # programs.gamemode.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
  ];
}
