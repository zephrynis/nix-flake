{ inputs, pkgs, ... }:

{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    gamescopeSession.enable = true; # "Steam (gamescope)" session in SDDM
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  # programs.gamescope.capSysNice = true; # left off — known to break gamescope under Steam

  environment.systemPackages = with pkgs; [
    mangohud
    prismlauncher
    protonup-qt
  ];

  # Minecraft Bedrock via mcpelauncher (unofficial; runs the Android ARM build
  # through a libc shim — you must own Bedrock on Google Play). Installed as a
  # Flatpak (io.mrarm.mcpelauncher) rather than the nixpkgs package, whose
  # launcher lagged the newer, pairip-protected Bedrock releases. nix-flatpak
  # adds the Flathub remote (its default) and installs the app on activation.
  services.flatpak = {
    enable = true;
    packages = [ "io.mrarm.mcpelauncher" ];
  };
}
