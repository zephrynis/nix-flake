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

    # GTK4 screenshare picker with live window/monitor previews — replaces the
    # bare Qt hyprland-share-picker bundled with XDPH. Needs submodules.
    hyprland-preview-share-picker = {
      url = "git+https://github.com/WhySoBad/hyprland-preview-share-picker?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Firefox extensions (rycee's firefox-addons, the set behind
    # nur.repos.rycee.firefox-addons — avoids importing all of NUR). Imported
    # as a source tree via callPackage rather than its flake output so the
    # addons evaluate under the system nixpkgs (needed for allowUnfree, e.g.
    # the 1Password extension).
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions";
      flake = false;
    };

    # Main UI font of the current end-4 dots. Their installer clones this repo
    # directly (the font is Google-proprietary, so no distro packages it).
    google-sans-flex = {
      url = "github:end-4/google-sans-flex";
      flake = false;
    };

    # Declarative Spicetify (Spotify client mods). The home-manager module
    # installs its own wrapped Spotify — pkgs.spotify must NOT be added anywhere.
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpak app/remote management (extends services.flatpak). Used
    # for the Minecraft Bedrock launcher, whose Flatpak build tracks newer,
    # pairip-protected Bedrock releases ahead of the nixpkgs package.
    nix-flatpak.url = "github:gmodena/nix-flatpak";
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
