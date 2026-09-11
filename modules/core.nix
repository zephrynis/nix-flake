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

  # mcvcli downloads an upstream Java runtime into ~/.mcvcli. Its ELF binaries
  # use the conventional /lib64 Linux loader path, so they need NixOS's
  # compatibility loader rather than a Nix-store-patched interpreter.
  programs.nix-ld.enable = true;

  networking.networkmanager.enable = true; # required by illogical-flake

  # Firmware blobs for Realtek RTL8821CU WiFi/Bluetooth dongle (and other devices)
  hardware.enableRedistributableFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      FastConnectable = true;
      JustWorksRepairing = "always";
    };
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
    openvpn    # DataPacket IPMI VPN (run: sudo openvpn --config <file>.ovpn)
  ];
}
