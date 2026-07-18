{ pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  networking.networkmanager.enable = true; # required by illogical-flake

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;

  services.fstrim.enable = true;

  # Read the Windows/data partitions when needed
  boot.supportedFilesystems = [ "ntfs" ];

  environment.systemPackages = with pkgs; [
    wget
    curl
    file
    unzip
    p7zip
    pciutils
    usbutils
    efibootmgr # check/fix boot order so rEFInd stays first
  ];
}
