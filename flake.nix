{
  description = "nixos-pc — NixOS + Hyprland (end-4 illogical-impulse)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # end-4 dots-hyprland (illogical-impulse) home-manager port
    illogical-flake = {
      url = "github:soymou/illogical-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      # To pin or fork the end-4 dotfiles themselves, override the port's
      # `dotfiles` input (this is the only source-override mechanism):
      # inputs.dotfiles.url = "git+https://github.com/end-4/dots-hyprland?submodules=1&rev=<sha>";
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos-pc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/nixos-pc

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.backupFileExtension = "hm-bak";
          home-manager.users.zephrynis = import ./home/zephrynis.nix;
        }
      ];
    };
  };
}
