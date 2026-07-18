{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/nvidia.nix
    ../../modules/gaming.nix
  ];

  networking.hostName = "nixos-pc";

  # systemd-boot lives on this install's OWN ESP (on the 1TB WD SSD) and only
  # serves NixOS generations. rEFInd on the NVMe ESP stays the top-level OS
  # picker and auto-detects this as a new entry — do not add Windows/Arch
  # entries here.
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };

  users.users.zephrynis = {
    isNormalUser = true;
    description = "zephrynis";
    extraGroups = [ "wheel" "networkmanager" "video" "input" ];
    shell = pkgs.fish; # end-4 dots are fish-centric
  };
  programs.fish.enable = true;

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # Set to the NixOS release of the ISO used at install time; never change afterwards.
  system.stateVersion = "25.11";
}
