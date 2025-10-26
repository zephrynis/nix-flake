{ config, pkgs, ... }:

{
  # Laptop specific configuration
  
  networking.hostName = "laptop";

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

  # Laptop-specific power management
  services.tlp = {
    enable = true;
    settings = {
      # Battery thresholds (for supported laptops)
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;
      
      # CPU scaling
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };

  # Enable powertop for additional power savings
  powerManagement.powertop.enable = true;

  # Laptop-specific packages
  environment.systemPackages = with pkgs; [
    # Add laptop-specific packages here
    brightnessctl  # Screen brightness control
    acpi           # Battery info
  ];

  # Enable touchpad support
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
      disableWhileTyping = true;
    };
  };

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
