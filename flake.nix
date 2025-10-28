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
    
    # Optional: Other useful inputs
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs: {
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
                "DP-2,2560x1440@165,0x0,1"    # Main monitor (1440p @ 165Hz)
                "DP-1,3840x2160@60,2560x0,1"  # 4K monitor to the right
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
