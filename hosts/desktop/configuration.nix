{ config, pkgs, lib, inputs,  ... }:

{
  imports = [
    ../../system/nvidia.nix
  ];
  
  # Desktop PC specific configuration
  # RTX 3080 - Enable open-source kernel module for better performance
  hardware.nvidia.open = lib.mkForce true;
  
  networking.hostName = "zeph-desktop";

  # Configure monitors for login screen (display manager)
  services.displayManager.sddm.settings = {
    General = {
      DisplayServer = "wayland";
    };
    
    # Wayland-specific settings
    Wayland = {
      SessionDir = "/run/current-system/sw/share/wayland-sessions";
      CompositorCommand = "${pkgs.hyprland}/bin/Hyprland -c /etc/sddm/hyprland.conf";
    };
  };
  
  # Create a Hyprland config for SDDM to set monitor order
  # DP-2 (1440p 165Hz) is primary on the left, DP-1 (4K 60Hz) is secondary on the right
  environment.etc."sddm/hyprland.conf".text = ''
    monitor=DP-2,2560x1440@165,0x0,1
    monitor=DP-1,3840x2160@60,2560x0,1.5
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
  programs.steam.enable = true;
  programs.gamemode.enable = true;
}
