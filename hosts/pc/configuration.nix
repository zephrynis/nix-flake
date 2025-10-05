{ config, lib, pkgs, inputs, user, ... }:
{
  imports = [
    ../../modules/common.nix
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "pc";

  # Host-specific tweaks
  services.printing.enable = true; # example: enable printing on PC

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
