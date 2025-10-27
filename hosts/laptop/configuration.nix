{ config, pkgs, inputs, ... }:

{
  # Laptop specific configuration
  
  networking.hostName = "zeph-laptop";

  # Users configuration
  users.users.zeph = {
    isNormalUser = true;
    description = "Zephrynis";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Hyprland - Tiling Wayland compositor
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
  };
  
  # Enable X11 for XWayland support
  services.xserver = {
    enable = true;
  };
  
  # Use SDDM for login (works with Wayland)
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Laptop-specific power management
  # Choose either TLP or power-profiles-daemon (not both)
  # TLP is more advanced, power-profiles-daemon is simpler and integrates better with KDE
  
  # Option 1: Use TLP (more features)
  services.power-profiles-daemon.enable = false;  # Disable to use TLP
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
  
  # Option 2: Use power-profiles-daemon (uncomment to use instead of TLP)
  # services.tlp.enable = false;
  # services.power-profiles-daemon.enable = true;

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
