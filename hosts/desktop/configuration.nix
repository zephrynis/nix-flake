{ config, pkgs, lib, inputs,  ... }:

{
  imports = [
    ../../system/nvidia.nix
  ];
  
  # Desktop PC specific configuration
  # RTX 3080 - Enable open-source kernel module for better performance
  hardware.nvidia.open = lib.mkForce true;
  
  networking.hostName = "zeph-desktop";

  # Configure monitors for SDDM (display manager)
  # This ensures the login screen appears on the 1440p monitor
  services.displayManager.sddm.settings = {
    General = {
      DisplayServer = "wayland";
    };
  };
  
  # Create a Hyprland config for SDDM to set monitor order
  environment.etc."sddm/hyprland.conf".text = ''
    monitor=DP-2,2560x1440@165,0x0,1
    monitor=DP-1,3840x2160@60,2560x0,1
  '';

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
