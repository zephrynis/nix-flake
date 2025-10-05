{ config, lib, pkgs, ... }:
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  time.timeZone = "UTC";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
    };
  };

  console = {
    keyMap = "us";
    earlySetup = true;
  };

  networking.networkmanager.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  security.sudo.wheelNeedsPassword = false;

  users.defaultUserShell = pkgs.bashInteractive; # change to zsh if preferred

  environment.systemPackages = with pkgs; [
    alacritty
    # Custom Zen Browser package (defined in ../packages/zen-browser.nix)
    (pkgs.callPackage ../packages/zen-browser.nix { inherit (pkgs) buildMozillaMach buildNpmPackage fetchFromGitHub lib fetchurl git pkg-config python3 vips runtimeShell writeScriptBin; })
  ];

  # Allow proprietary software if needed
  nixpkgs.config = {
    allowUnfree = true;
    # Permit evaluation of packages marked broken (zen-browser currently sets broken = true)
    allowBroken = true;
  };

  # Set the minimal stateVersion. When you upgrade, bump per host.
  system.stateVersion = "24.05"; # do not change without reading the manual
}
