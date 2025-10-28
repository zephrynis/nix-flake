{ config, pkgs, lib, inputs,  ... }:

{
  imports = [
    ../../system/nvidia.nix
  ];
  
  # Desktop PC specific configuration
  # RTX 3080 - Enable open-source kernel module for better performance
  hardware.nvidia.open = lib.mkForce true;
  
  networking.hostName = "zeph-desktop";

  # Desktop-specific packages (gaming, streaming, etc.)
  environment.systemPackages = with pkgs; [
    # Add desktop-specific packages here
    # discord
    # steam
    # obs-studio
    
    # NVIDIA utilities
    nvtopPackages.full  # GPU monitoring tool
    vulkan-tools        # Vulkan utilities (vulkaninfo, etc.)
    glxinfo             # OpenGL information
  ];

  # Gaming support (uncomment if needed)
  # programs.steam.enable = true;
  # programs.gamemode.enable = true;
}
