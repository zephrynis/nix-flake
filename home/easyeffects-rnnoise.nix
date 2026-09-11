{ pkgs, ... }:

let
  presetName = "rnnoise-discord";
  loadPreset = pkgs.writeShellScript "load-easyeffects-rnnoise-routing" ''
    # EasyEffects owns this socket once its background service is ready.
    # Waiting avoids a login race with the desktop autostart entry.
    for _ in {1..30}; do
      if [ -S "$XDG_RUNTIME_DIR/EasyEffectsServer" ]; then
        exec ${pkgs.easyeffects}/bin/easyeffects --load-preset ${presetName}
      fi
      ${pkgs.coreutils}/bin/sleep 1
    done

    echo "EasyEffects did not become ready; RNNoise routing preset was not loaded" >&2
    exit 1
  '';
in
{
  # EasyEffects' "Process all inputs" feature otherwise moves Discord away
  # from rnnoise_source and back onto Easy Effects Source. Excluding Discord
  # leaves the intended chain intact:
  #   physical mic -> EasyEffects -> RNNoise -> Discord
  xdg.dataFile."easyeffects/input/${presetName}.json".text = builtins.toJSON {
    input = {
      blocklist = [ "WEBRTC VoiceEngine" ];
      plugins_order = [ ];
    };
  };

  systemd.user.services.easyeffects-rnnoise-routing = {
    Unit = {
      Description = "Keep Discord capture routed through RNNoise";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = loadPreset;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
