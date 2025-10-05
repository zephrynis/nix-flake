{
  description = "Nix flake for PC and laptop with shared modules and Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05"; # You can bump to a newer release later (e.g., nixos-24.11)

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      # Change this to your preferred login name once you clone on the machine(s)
      user = "user";

      mkFormatter = system: let pkgs = import nixpkgs { inherit system; }; in pkgs.alejandra;
    in
    {
  # Two NixOS hosts. This flake targets x86_64-linux only.
      nixosConfigurations = {
        pc = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit user;
            # Only pass what host modules need from inputs to stay tidy
            inputs = { inherit home-manager; };
          };
          modules = [ ./hosts/pc/configuration.nix ];
        };

        laptop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit user;
            inputs = { inherit home-manager; };
          };
          modules = [ ./hosts/laptop/configuration.nix ];
        };
      };

      # `nix fmt` support
      formatter = {
        x86_64-linux = mkFormatter "x86_64-linux";
      };

      # Expose custom packages
      packages = {
        x86_64-linux = let
nixpkgs48 = nixpkgs; # alias
          pkgs = import nixpkgs { system = "x86_64-linux"; };
        in {
          zen-browser = pkgs.callPackage ./packages/zen-browser.nix { inherit (pkgs) buildMozillaMach buildNpmPackage fetchFromGitHub lib fetchurl git pkg-config python3 vips runtimeShell writeScriptBin; };
        };
      };
    };
}
