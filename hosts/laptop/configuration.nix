{ config, lib, pkgs, inputs, user, ... }:
{
  imports = [
    ../../modules/common.nix
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "laptop";

  # Host-specific tweaks
  powerManagement.powertop.enable = true; # example: laptop power savings
  services.tlp.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Home Manager user wiring
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user} = import ../../home/users/${user}/home.nix;
  };
}
