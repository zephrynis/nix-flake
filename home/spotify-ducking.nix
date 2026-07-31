{ pkgs, ... }:

# Voice-activity ducking: while you OR someone else is speaking in a Discord
# (Vesktop) voice call, Spotify's volume is lowered; it returns to normal a
# beat after everyone goes quiet. Nothing else on the system is touched.
#
# The daemon (./spotify-duck.py) meters Discord's own output stream and your
# denoised mic (rnnoise_source, from modules/noise-suppression.nix) directly via
# `pw-record`, so it never reroutes audio and is independent of which output
# device is active. See that file's header for the full rationale. Tune the
# behaviour with the Environment entries below and `systemctl --user restart
# spotify-duck` (no rebuild needed to experiment; make it permanent here after).

let
  spotify-duck = pkgs.writeShellApplication {
    name = "spotify-duck";
    # pw-record/pw-dump live in pipewire; wpctl in wireplumber; python3 to run it.
    runtimeInputs = [ pkgs.python3 pkgs.pipewire pkgs.wireplumber ];
    text = ''exec python3 ${./spotify-duck.py} "$@"'';
  };
in
{
  systemd.user.services.spotify-duck = {
    Unit = {
      Description = "Duck Spotify while speaking on Discord (voice-activity)";
      After = [ "pipewire.service" "wireplumber.service" ];
    };

    Service = {
      ExecStart = "${spotify-duck}/bin/spotify-duck";
      Restart = "on-failure";
      RestartSec = 3;
      # Tuning knobs — override and `systemctl --user restart spotify-duck`.
      Environment = [
        "DUCK_LEVEL=0.35"       # ducked volume = your current volume * this (35%)
        "MIC_THRESHOLD=0.004"   # you-speaking RMS gate (measured: speech 0.004-0.015,
                                #   silence <0.0025 on rnnoise_source). Lower toward
                                #   0.003 if soft speech is missed; raise if it dips
                                #   randomly.
        "DISC_THRESHOLD=0.008"  # others-speaking RMS gate on Discord's output
        "RELEASE_MS=900"        # restore this long after the last speech
        "MIC_TARGET=rnnoise_source"  # mic node; the denoised source you use in Discord
        "DISCORD_APP=vesktop"        # application.name of the Discord client
        "SPOTIFY_MATCH=spotify"      # substring identifying Spotify's stream
      ];
    };

    # default.target (not graphical-session.target) so it reliably starts on
    # login regardless of how the Hyprland session activates targets; the daemon
    # tolerates PipeWire not being up yet and self-heals.
    Install.WantedBy = [ "default.target" ];
  };
}
