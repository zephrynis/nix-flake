{ pkgs, ... }:

{
  services.tailscale = {
    enable = true;
    # Let zephrynis drive the daemon without sudo — required for Trayscale,
    # and makes `tailscale switch` / `login` work from a plain shell too
    extraSetFlags = [ "--operator=zephrynis" ];
  };

  # Tray app for the bar's systray: status toggle + account switcher
  # (work/personal via Tailscale fast user switching). Autostarted from
  # hypr/custom/execs.lua (appended in home/zephrynis.nix).
  environment.systemPackages = [ pkgs.trayscale ];
}
