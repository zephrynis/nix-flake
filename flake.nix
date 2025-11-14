{
  description = "NixOS system configuration flake with ricing and application management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    
    # Home Manager for user-level configuration and dotfiles
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Hyprland - Tiling Wayland compositor
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    
    # Vicinae - Application launcher
    vicinae.url = "github:vicinaehq/vicinae";
    
    # Astal - Required for AGS
    astal.url = "github:aylur/astal";
    astal.inputs.nixpkgs.follows = "nixpkgs";
    
    # AGS - Aylur's GTK Shell for custom widgets/bar (v3)
    ags.url = "github:Aylur/ags";
    ags.inputs.nixpkgs.follows = "nixpkgs";
    ags.inputs.astal.follows = "astal";
    
    # Spicetify - Spotify customization
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    
    # Optional: Other useful inputs
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, home-manager, hyprland, vicinae, astal, ags, spicetify-nix, ... }@inputs: {
    # NixOS configuration for your hostname(s)
    nixosConfigurations = {
      # Desktop PC configuration
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Your hardware configuration
          ./hosts/desktop/hardware-configuration.nix
          
          # System-wide configuration
          ./hosts/desktop/configuration.nix
          
          # Common system configuration shared across all machines
          ./system/common.nix
          
          # Home Manager NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.backupFileExtension = "backup";
            
            # User configuration with desktop-specific overrides
            home-manager.users.zeph = { lib, ... }: {
              imports = [ ./home/home.nix ];
              
              # Desktop-specific Hyprland monitor configuration
              wayland.windowManager.hyprland.settings.monitor = lib.mkForce [
                "DP-2,2560x1440@165,0x0,1"      # Main monitor (1440p @ 165Hz) at origin
                "DP-1,3840x2160@60,2560x0,1.5"  # 4K monitor to the right with 1.5x scale
              ];
              
              # Assign workspaces to specific monitors
              wayland.windowManager.hyprland.settings.workspace = [
                "1, monitor:DP-2, default:true"
                "2, monitor:DP-1"
                "3, monitor:DP-2"
                "4, monitor:DP-1"
                "5, monitor:DP-2"
                "6, monitor:DP-1"
                "7, monitor:DP-2"
                "8, monitor:DP-1"
                "9, monitor:DP-2"
                "10, monitor:DP-1"
              ];
            };
          }
        ];
      };
      
      # Laptop configuration
      laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          # Your hardware configuration
          ./hosts/laptop/hardware-configuration.nix
          
          # System-wide configuration
          ./hosts/laptop/configuration.nix
          
          # Common system configuration shared across all machines
          ./system/common.nix
          
          # Home Manager NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.backupFileExtension = "backup";
            
            # User configuration
            home-manager.users.zeph = import ./home/home.nix;
          }
        ];
      };
    };
  };
}
