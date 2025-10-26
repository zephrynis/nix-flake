{
  description = "NixOS system configuration flake with ricing and application management";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    
    # Home Manager for user-level configuration and dotfiles
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Optional: Hyprland (if you want a tiling Wayland compositor)
    # hyprland.url = "github:hyprwm/Hyprland";
    
    # Optional: Other useful inputs
    # nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
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
            
            # User configuration
            home-manager.users.zeph = import ./home/home.nix;
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
