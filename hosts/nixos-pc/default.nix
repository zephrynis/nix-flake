{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/nvidia.nix
    ../../modules/gaming.nix
    ../../modules/tailscale.nix
    ../../modules/noise-suppression.nix
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

  # 1Password desktop app + CLI. The module (vs a plain package) sets up the
  # polkit policy for system-auth unlock and the setgid onepassword group the
  # browser integration needs.
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "zephrynis" ];
  };
  programs._1password.enable = true;
  # 1Password verifies the browser binary's name before connecting the
  # extension to the app; NixOS's wrapped Firefox isn't on its allowlist
  environment.etc."1password/custom_allowed_browsers" = {
    text = ".firefox-wrapped";
    mode = "0755";
  };

  time.timeZone = "Europe/London";
  i18n.defaultLocale = "en_GB.UTF-8";

  # Set to the NixOS release of the ISO used at install time; never change afterwards.
  system.stateVersion = "26.05";
}
