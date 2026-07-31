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

  # Some devices expose a control interface that udev misdetects as a joystick,
  # so Steam/games pick up a phantom controller and grab input. Clear
  # ID_INPUT_JOYSTICK for them (extraRules → 99-local.rules is fine here, since
  # this only rewrites a udev property later consumers read):
  #   3434 = Keychron keyboard
  #   3151 = "2.4G Wireless Mouse" (X3PRO) receiver
  services.udev.extraRules = ''
    SUBSYSTEM=="input", ATTRS{idVendor}=="3434", ENV{ID_INPUT_JOYSTICK}=""
    SUBSYSTEM=="input", ATTRS{idVendor}=="3151", ENV{ID_INPUT_JOYSTICK}=""
  '';

  # Browser-based (WebHID) configurators need the logged-in user to have access
  # to the device's raw HID nodes:
  #   3434 = Keychron keyboard   (launcher.keychron.com)
  #   3151 = X3PRO mouse         (its web editor)
  # TAG+="uaccess" makes systemd-logind grant the active session an ACL — but
  # that tag is CONSUMED by systemd's 73-seat-late.rules, so the rule must sort
  # BEFORE it. services.udev.extraRules lands in 99-local.rules (too late), so
  # ship this as a package-provided 60-*.rules file instead.
  # (WebHID is Chromium-only — use Chrome, not Firefox.)
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "hid-webconfig-uaccess";
      destination = "/etc/udev/rules.d/60-hid-webconfig-uaccess.rules";
      text = ''
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", TAG+="uaccess"
        KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3151", TAG+="uaccess"
      '';
    })
  ];
}
