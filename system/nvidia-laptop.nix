{ config, pkgs, ... }:

{
  # NVIDIA Configuration for Laptop with Hybrid Graphics (Intel + GTX 1050)
  
  # Enable OpenGL and NVIDIA drivers
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Load NVIDIA driver
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Modesetting required for Wayland
    modesetting.enable = true;

    # NVIDIA power management
    # Recommended for laptops to save battery
    powerManagement.enable = true;
    
    # Fine-grained power management
    # Turns off GPU when not in use - EXPERIMENTAL
    # Can help with battery life but may cause issues
    powerManagement.finegrained = false;

    # GTX 1050 is Pascal architecture - must use proprietary driver
    open = false;

    # Enable nvidia-settings
    nvidiaSettings = true;

    # Use stable driver
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME configuration for hybrid graphics
    prime = {
      # Offload mode: Intel for regular use, NVIDIA on-demand
      # This saves battery by keeping NVIDIA GPU off most of the time
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Adds nvidia-offload command
      };
      
      # IMPORTANT: Find your actual Bus IDs with: sudo lshw -c display
      # Then update these values accordingly
      # Example output:
      #   Intel: bus info: pci@0000:00:02.0 → intelBusId = "PCI:0:2:0"
      #   NVIDIA: bus info: pci@0000:01:00.0 → nvidiaBusId = "PCI:1:0:0"
      
      # Placeholder values - UPDATE THESE!
      intelBusId = "PCI:0:2:0";    # Usually correct for Intel iGPU
      nvidiaBusId = "PCI:1:0:0";   # Common for laptop discrete GPU
      
      # Alternative: Use sync mode instead of offload
      # This runs everything on NVIDIA (worse battery, better performance)
      # Uncomment to enable:
      # sync.enable = true;
      # offload.enable = false;  # Disable offload if using sync
    };
  };

  # Kernel parameters for better NVIDIA support
  boot.kernelParams = [ 
    "nvidia-drm.modeset=1"  # Required for Wayland
  ];
  
  # Create nvidia-offload command for easy GPU switching
  # Usage: nvidia-offload <program>
  # Example: nvidia-offload glxgears
  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "nvidia-offload" ''
      export __NV_PRIME_RENDER_OFFLOAD=1
      export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export __VK_LAYER_NV_optimus=NVIDIA_only
      exec "$@"
    '')
  ];
}
