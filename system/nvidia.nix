{ config, pkgs, ... }:

{
  # NVIDIA Driver Configuration for NixOS
  
  # Enable OpenGL and NVIDIA drivers
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  # For 32-bit applications (games, Wine, etc.)
  };

  # Load NVIDIA driver for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting is required for Wayland
    modesetting.enable = true;

    # Enable power management (experimental)
    # Helps with suspend/resume and may reduce power consumption
    powerManagement.enable = false;
    
    # Fine-grained power management (turns off GPU when not in use)
    # Experimental and can cause sleep/suspend issues
    powerManagement.finegrained = false;

    # Use the open source kernel module (not nouveau, but nvidia-open)
    # Only works on Turing and newer (RTX 20 series+, GTX 16 series+)
    # RTX 3080 supports this, but GTX 1050 does not
    # This can be overridden per-host
    open = false;

    # Enable the Nvidia settings menu (nvidia-settings)
    nvidiaSettings = true;

    # Select the appropriate driver version
    # Options: stable, beta, legacy_470, legacy_390, legacy_340
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Optional: For laptop with hybrid graphics (Intel/AMD + NVIDIA)
  # Uncomment the following lines if you have a hybrid setup:
  
  # hardware.nvidia.prime = {
  #   # Make sure to use the correct Bus ID values for your system!
  #   # Find them with: sudo lshw -c display
  #   offload = {
  #     enable = true;
  #     enableOffloadCmd = true;
  #   };
  #   # Bus ID of the Intel GPU (example)
  #   intelBusId = "PCI:0:2:0";
  #   # Bus ID of the NVIDIA GPU (example)
  #   nvidiaBusId = "PCI:1:0:0";
  # };

  # Kernel parameters
  boot.kernelParams = [ 
    # Uncomment if you experience issues:
    # "nvidia-drm.modeset=1"
  ];
}
