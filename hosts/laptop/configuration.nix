{ config, pkgs, inputs, ... }:

{
  imports = [
    ../../system/nvidia-laptop.nix
  ];
  
  # Laptop specific configuration
  
  networking.hostName = "zeph-laptop";

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
    
    # NVIDIA utilities
    nvtopPackages.full  # GPU monitoring
    vulkan-tools        # Vulkan utilities
    glxinfo             # OpenGL info
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
}
