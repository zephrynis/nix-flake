{ config, pkgs, ... }:

{
  # Machine-specific configuration
  
  networking.hostName = "my-machine"; # Change this to your hostname

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
    
    # Display manager (choose one)
    displayManager.gdm.enable = true;
    # displayManager.sddm.enable = true;
    # displayManager.lightdm.enable = true;
    
    # Desktop environment (choose one, or comment all for a standalone WM)
    # desktopManager.gnome.enable = true;
    # desktopManager.plasma5.enable = true;
    # desktopManager.xfce.enable = true;
    
    # Window manager (uncomment if you want a standalone WM)
    # windowManager.i3.enable = true;
    # windowManager.bspwm.enable = true;
  };

  # Optional: Enable Wayland compositor
  # programs.hyprland = {
  #   enable = true;
  #   xwayland.enable = true;
  # };

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" "Iosevka" ]; })
  ];
}
