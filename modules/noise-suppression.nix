{ pkgs, ... }:

# App-independent microphone noise suppression via PipeWire + RNNoise.
#
# Replaces Discord's Krisp (which can't be enabled on current nixpkgs Discord:
# the binary is patchelf'd, and even after bypassing Krisp's signature check the
# newer "THz SDK" stage fails with KRISP_INIT_ERROR_GLOBAL_INIT). Instead we run
# RNNoise as a PipeWire filter-chain that exposes a cleaned virtual microphone.
#
# This works in EVERY app (Discord, browser, OBS, games), survives Discord
# updates, and touches no DRM. In each app's input settings, pick the source
# named "Noise Canceling source" instead of the raw mic.

{
  # LADSPA plugin providing noise_suppressor_mono/stereo (werman RNNoise).
  environment.systemPackages = [ pkgs.rnnoise-plugin ];

  services.pipewire.extraConfig.pipewire."99-input-denoising" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Noise Canceling source";
          "media.name" = "Noise Canceling source";
          "filter.graph" = {
            nodes = [
              {
                type = "ladspa";
                name = "rnnoise";
                plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                label = "noise_suppressor_mono";
                control = {
                  # Higher threshold = more aggressive gating of non-voice.
                  # 50% is a balanced starting point; raise toward 90–95 if a
                  # noisy background still leaks through, lower if speech clips.
                  "VAD Threshold (%)" = 50.0;
                  "VAD Grace Period (ms)" = 200.0;
                  "Retroactive VAD Grace (ms)" = 0.0;
                };
              }
              {
                # Makeup gain baked into the graph so the source volume is
                # reproducible instead of living only in WirePlumber's runtime
                # state. Mult = 1.53 matches the 153% level set in the mixer.
                type = "builtin";
                name = "gain";
                label = "linear";
                control = {
                  "Mult" = 1.53;
                  "Add" = 0.0;
                };
              }
            ];
            links = [
              { output = "rnnoise:Output"; input = "gain:In"; }
            ];
          };
          # The virtual mic apps select. media.class = Audio/Source makes it
          # appear as a capture device throughout the desktop.
          "capture.props" = {
            "node.name" = "capture.rnnoise_source";
            "node.passive" = true;
            "audio.rate" = 48000;
          };
          "playback.props" = {
            "node.name" = "rnnoise_source";
            "media.class" = "Audio/Source";
            "audio.rate" = 48000;
          };
        };
      }
    ];
  };
}
