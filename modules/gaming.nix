{ pkgs, ... }:

{
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
    protonup-qt
  ];
}
