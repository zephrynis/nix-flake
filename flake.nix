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

    # Minecraft server version manager. Packaged from its Cargo sources in the
    # home-manager config because it is not currently available in nixpkgs.
    mcvcli = {
      url = "github:mcjars/mcvcli";
      flake = false;
    };

    # Minecraft Bedrock for Windows running through the upstream Wine/Proton
    # launcher. Pin a release so system rebuilds remain reproducible.
    bedrock-on-linux = {
      url = "github:Wyze3306/BedrockOnLinux/v2.2.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Paseo desktop app: a local UI/daemon for driving coding agents remotely.
    # Keep its own locked nixpkgs so the upstream npm dependency hash remains
    # reproducible against the nixpkgs revision it is tested with.
    paseo.url = "github:getpaseo/paseo";

    # Unofficial Linux desktop distribution of OpenAI's ChatGPT/Codex app.
    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";

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

    # MCLauncher reuses Nixpkgs' Modrinth 0.19.1 source package so Cargo, Gradle,
    # and pnpm dependency hashes remain upstream-maintained. Keep this separate
    # from the system nixpkgs pin so adding the launcher cannot update the rest
    # of the machine underneath us.
    nixpkgs-mclauncher.url = "github:NixOS/nixpkgs/7a14922897bb1adb8f458a917d33ec9e1ca5ae18";
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
      mclauncherPkgs = import inputs.nixpkgs-mclauncher {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system}.mclauncher = import ./packages/mclauncher.nix {
        pkgs = mclauncherPkgs;
      };

      nixosConfigurations.nixos-pc = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/nixos-pc

          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.backupFileExtension = "hm-bak";
            home-manager.users.zephrynis = {
              imports = [
                ./home/zephrynis.nix
                ./home/mclauncher.nix
              ];
            };
          }
        ];
      };
    };
}
