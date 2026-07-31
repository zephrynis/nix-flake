#!/usr/bin/env python3
"""Voice-activity ducking: lower Spotify while you or others speak on Discord.

Design (see home/spotify-ducking.nix for the wiring):

  * "Someone else is speaking" is measured by tapping the MONITOR of Discord's
    (Vesktop's) own playback stream via `pw-record --target <serial>`. That
    captures ONLY Vesktop's output, so Spotify's own audio can never leak into
    the meter and cause a feedback duck.
  * "You are speaking" is measured by tapping your denoised mic (rnnoise_source)
    the same way -- but only counts while you're actually in a voice call, which
    we detect by Vesktop holding an open capture (Stream/Input/Audio) stream.
    So talking near your mic outside a call won't touch the music.
  * When either crosses its threshold we ride ONLY Spotify's own stream volume
    down to DUCK_LEVEL and back up after RELEASE_MS of silence. Nothing else on
    the system is affected, and we never reroute audio, so switching output
    devices (earbuds, headset, HDMI) needs no special handling.

Everything is discovered dynamically from `pw-dump`, so it survives Discord and
Spotify restarts, leaving/rejoining calls, and node-id churn. All tuning is via
environment variables (set in the systemd unit).
"""

import json
import math
import os
import signal
import struct
import subprocess
import threading
import time

# ---- tunables (overridable from the environment) --------------------------
RATE = 16000                                             # meter sample rate
FRAME_BYTES = int(RATE * 0.05) * 2                       # 50 ms of s16 mono
DUCK_LEVEL = float(os.environ.get("DUCK_LEVEL", "0.2"))  # ducked = base * this
MIC_TH = float(os.environ.get("MIC_THRESHOLD", "0.02"))  # you-speaking RMS gate
DISC_TH = float(os.environ.get("DISC_THRESHOLD", "0.012"))  # others-speaking gate
RELEASE = float(os.environ.get("RELEASE_MS", "700")) / 1000.0  # silence hold
MIC_TARGET = os.environ.get("MIC_TARGET", "rnnoise_source")    # mic node.name
DISCORD_APP = os.environ.get("DISCORD_APP", "vesktop")         # application.name
SPOTIFY_MATCH = os.environ.get("SPOTIFY_MATCH", "spotify").lower()
POLL = float(os.environ.get("POLL_SEC", "1.0"))          # graph-discovery period

PW_RECORD = "pw-record"
PW_DUMP = "pw-dump"
WPCTL = "wpctl"


def rms(buf):
    n = len(buf) // 2
    if n == 0:
        return 0.0
    s = struct.unpack("<%dh" % n, buf[: n * 2])
    return math.sqrt(sum(x * x for x in s) / n) / 32768.0


class Meter(threading.Thread):
    """Continuously reports the RMS level of one PipeWire node's monitor.

    `.target` is a node name or object.serial to capture, or None to pause.
    Restarts its `pw-record` automatically when the target changes or the
    captured stream goes away (e.g. Discord closes it on call end).
    """

    def __init__(self):
        super().__init__(daemon=True)
        self.level = 0.0
        self._target = None
        self._cur = None
        self._proc = None
        self._lock = threading.Lock()

    def set_target(self, t):
        with self._lock:
            self._target = t

    def _start(self, tgt):
        self._proc = subprocess.Popen(
            [PW_RECORD, "--target", str(tgt), "--rate", str(RATE),
             "--channels", "1", "--format", "s16", "--latency", "50ms", "-"],
            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
        )
        self._cur = tgt

    def _stop(self):
        if self._proc:
            self._proc.terminate()
            try:
                self._proc.wait(1)
            except subprocess.TimeoutExpired:
                self._proc.kill()
        self._proc, self._cur = None, None

    def run(self):
        while True:
            with self._lock:
                tgt = self._target
            if tgt is None:
                self._stop()
                self.level = 0.0
                time.sleep(0.1)
                continue
            if tgt != self._cur:
                self._stop()
                self._start(tgt)
            buf = b""
            while len(buf) < FRAME_BYTES:
                chunk = self._proc.stdout.read(FRAME_BYTES - len(buf))
                if not chunk:
                    break
                buf += chunk
            if not buf:                      # stream ended -> respawn next loop
                self._stop()
                self.level = 0.0
                time.sleep(0.1)
                continue
            self.level = rms(buf)


# shared graph state, refreshed by the discovery thread
G = {"discord_serial": None, "in_call": False, "spotify_id": None}


def discover():
    while True:
        try:
            dump = json.loads(subprocess.check_output([PW_DUMP]))
        except Exception:
            time.sleep(POLL)
            continue
        dser = incall = spid = None
        incall = False
        for o in dump:
            if o.get("type") != "PipeWire:Interface:Node":
                continue
            p = (o.get("info") or {}).get("props") or {}
            mc = p.get("media.class", "")
            app = (p.get("application.name") or "")
            binn = (p.get("application.process.binary") or "").lower()
            nn = (p.get("node.name") or "").lower()
            if mc == "Stream/Output/Audio" and app == DISCORD_APP:
                dser = p.get("object.serial")
            elif mc == "Stream/Input/Audio" and app == DISCORD_APP:
                incall = True
            elif mc == "Stream/Output/Audio" and (
                SPOTIFY_MATCH in app.lower() or SPOTIFY_MATCH in binn
                or SPOTIFY_MATCH in nn
            ):
                spid = o["id"]
        G.update(discord_serial=dser, in_call=incall, spotify_id=spid)
        time.sleep(POLL)


def get_vol(nid):
    try:
        out = subprocess.check_output(
            [WPCTL, "get-volume", str(nid)], stderr=subprocess.DEVNULL
        ).decode()
        return float(out.split()[1])          # "Volume: 0.42 [MUTED]" -> 0.42
    except Exception:
        return None


def set_vol(nid, v):
    v = max(0.0, min(1.5, v))
    subprocess.run([WPCTL, "set-volume", str(nid), "%.3f" % v],
                   stderr=subprocess.DEVNULL, check=False)


# ducking state, shared so the SIGTERM handler can un-duck on shutdown.
# `base` is your genuine chosen volume; it is ONLY ever sampled while un-ducked
# and settled (see the control loop), so our own ducked writes can never feed
# back into it and ratchet the volume toward zero.
S = {"ducked": False, "base": 1.0, "spid": None}
_slock = threading.Lock()
SETTLE = 0.5  # seconds to let a wpctl write propagate before trusting a read


def restore_and_exit(*_):
    with _slock:
        if S["ducked"] and S["spid"] is not None:
            set_vol(S["spid"], S["base"])
    os._exit(0)


def main():
    signal.signal(signal.SIGTERM, restore_and_exit)
    signal.signal(signal.SIGINT, restore_and_exit)

    mic, disc = Meter(), Meter()
    mic.start()
    disc.start()
    threading.Thread(target=discover, daemon=True).start()

    last_voice = 0.0
    known_spid = None      # Spotify node we've already learned the base volume of
    base_deadline = 0.0    # don't sample base again until monotonic() past this
    while True:
        in_call = G["in_call"]
        spid = G["spotify_id"]
        # only meter while in a call -> zero idle CPU otherwise
        mic.set_target(MIC_TARGET if in_call else None)
        disc.set_target(G["discord_serial"] if in_call else None)

        now = time.monotonic()
        if in_call and (mic.level > MIC_TH or disc.level > DISC_TH):
            last_voice = now
        want_duck = in_call and (now - last_voice) < RELEASE

        with _slock:
            S["spid"] = spid
            if spid is None:
                S["ducked"] = False          # nothing to control
                known_spid = None
            else:
                if spid != known_spid:       # new Spotify stream: learn its volume
                    known_spid = spid
                    v = get_vol(spid)
                    if v is not None:
                        S["base"] = v
                    S["ducked"] = False
                    base_deadline = now + SETTLE
                if want_duck and not S["ducked"]:
                    set_vol(spid, S["base"] * DUCK_LEVEL)
                    S["ducked"] = True
                    base_deadline = now + SETTLE
                elif not want_duck and S["ducked"]:
                    set_vol(spid, S["base"])
                    S["ducked"] = False
                    base_deadline = now + SETTLE
                elif not S["ducked"] and now >= base_deadline:
                    # un-ducked and our last write has settled: this reading is
                    # your real volume, so adopt it (picks up manual changes).
                    v = get_vol(spid)
                    if v is not None:
                        S["base"] = v
                    base_deadline = now + SETTLE

        time.sleep(0.03)


if __name__ == "__main__":
    main()
