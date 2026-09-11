{ inputs, pkgs, ... }:

let
  # Hyprland 0.56.0 emits malformed JSON for `hyprctl binds -j`, leaving the
  # illogical-impulse Super+/ cheatsheet empty. 0.56.1 fixed the serializer;
  # use the latest patch release without advancing the entire nixpkgs pin.
  # Remove this override once the pinned nixpkgs already ships >= 0.56.1.
  hyprlandFixed = pkgs.hyprland.overrideAttrs (oldAttrs: {
    version = "0.56.2";
    src = pkgs.fetchFromGitHub {
      owner = "hyprwm";
      repo = "hyprland";
      fetchSubmodules = true;
      tag = "v0.56.2";
      hash = "sha256-jOcfiv+Zs2iz5oTIQcJXZ0+5MfqW0oLgGxD0cKdmXpE=";
    };
    env = oldAttrs.env // {
      GIT_BRANCH = "v0.56.2-b";
      GIT_COMMIT_DATE = "2026-08-05";
      GIT_COMMIT_HASH = "efb50993780079460b0cbed1363e2166a2de1d9f";
      GIT_COMMIT_MESSAGE = "[gha] Nix: update inputs";
      GIT_TAG = "v0.56.2";
    };
  });
in
{
  # System-side requirements of illogical-flake (the HM module does the rest)
  programs.hyprland = {
    enable = true;
    package = hyprlandFixed;
    withUWSM = false; # UWSM session black-screens (NVIDIA env vars + non-UWSM-aware dots)
  };
  services.geoclue2.enable = true; # QtPositioning — weather / night light widgets

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Boot straight into Hyprland; the illogical-impulse lock screen acts as the
  # login page (lock.launchOnStartup in ~/.config/illogical-impulse/config.json)
  services.displayManager.autoLogin = {
    enable = true;
    user = "zephrynis";
  };
  services.displayManager.defaultSession = "hyprland";

  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # file pickers etc.

  # Qt app theming (Prism Launcher, protonup-qt, …), matching upstream Arch:
  # the dots set QT_QPA_PLATFORMTHEME=kde and write wallpaper Material You
  # colors + widgetStyle=Darkly into ~/.config/kdeglobals, assuming
  # plasma-integration and Darkly are system-installed (like Bibata). The
  # illogical-flake port overrides the platform theme to qt6ct in
  # hypr/custom/env.lua — countered in home/zephrynis.nix. No qt.style here:
  # QT_STYLE_OVERRIDE would beat kdeglobals' widgetStyle.
  qt = {
    enable = true;
    platformTheme = "kde";
  };
  environment.systemPackages = [ pkgs.darkly ]; # Qt6 only; no qt5 variant in nixpkgs

  security.polkit.enable = true;
  programs.dconf.enable = true;
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;

  fonts.packages = with pkgs; [
    # Fonts the current dots actually use (config.json appearance.fonts):
    # main/title/numbers = Google Sans Flex, reading = Readex Pro,
    # expressive = Space Grotesk. Without these everything silently falls
    # back to DejaVu Sans.
    (runCommand "google-sans-flex-font" { } ''
      install -Dm644 ${inputs.google-sans-flex}/*.ttf -t $out/share/fonts/truetype
    '')
    readexpro
    (google-fonts.override { fonts = [ "SpaceGrotesk" ]; })

    # named by the illogical-flake README
    rubik
    nerd-fonts.ubuntu
    nerd-fonts.jetbrains-mono
    material-symbols
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
