#!/usr/bin/env python3
"""Synthesises the five Session sounds into App/Breathnest/Sounds/<sound-id>-<cue>.caf (#210, decisions in #49):
the cues are inhale, exhale (a fifth lower) and tick (for the holds).

Own work, no samples: a few decaying partials per sound, mono 44.1 kHz 16-bit PCM, peak at -6 dBFS.
Deterministic (a seeded noise source), so running it again reproduces the files byte for byte.
Needs macOS: `afconvert` wraps the generated WAV in a CAF container.

    python3 -I scripts/generate-sounds.py
"""
import math
import random
import struct
import subprocess
import sys
import tempfile
import wave
from pathlib import Path

RATE = 44_100
PEAK = 0.5  # -6 dBFS
OUT = Path(__file__).resolve().parent.parent / "App" / "Breathnest" / "Sounds"


def partials(base, parts, length, attack=0.005):
    """Sum of decaying sines. `parts` is (frequency ratio, level, decay seconds); `attack` is a short fade-in."""
    count = int(RATE * length)
    out = [0.0] * count
    for ratio, level, decay in parts:
        step = 2 * math.pi * base * ratio / RATE
        for i in range(count):
            t = i / RATE
            out[i] += level * math.sin(step * i) * math.exp(-t / decay)
    return [x * min(1.0, (i / RATE) / attack) for i, x in enumerate(out)]


# Each sound is a few decaying partials: (frequency ratio, level, decay seconds), a base frequency, a length and
# a fade-in. The cues are made from it: the inhale tone at the base frequency, the exhale tone a fifth lower, and a
# tick (a short, higher, quicker-decaying version) for the holds.
BELL = dict(base=523.25, parts=[(1, 1.0, 0.9), (2.76, 0.45, 0.5), (5.4, 0.2, 0.3), (8.93, 0.08, 0.15)], length=3.0, attack=0.004)
# Pairs a few cents apart beat slowly, which gives the bowl its slow shimmer.
BOWL = dict(
    base=220.0, parts=[(1, 1.0, 2.2), (1.004, 0.8, 2.0), (2.71, 0.4, 1.4), (2.72, 0.35, 1.3), (5.12, 0.15, 0.8)],
    length=4.5, attack=0.06,
)
CHIME = dict(base=1318.5, parts=[(1, 1.0, 0.7), (2.0, 0.35, 0.4), (3.01, 0.2, 0.25), (4.2, 0.08, 0.12)], length=2.5, attack=0.002)
# The pulse sits above 150 Hz and carries a second partial, so a phone speaker can play it.
PULSE = dict(base=196.0, parts=[(1, 1.0, 0.25), (2, 0.5, 0.2)], length=0.7, attack=0.12)


def tone(spec, ratio):
    """The sound at `ratio` times its base frequency."""
    return partials(spec["base"] * ratio, spec["parts"], spec["length"], spec["attack"])


def tick(spec, ratio, decay_scale=0.12, length=0.35):
    """A short, quick-decaying version of the sound, about as long as a haptic tick."""
    parts = [(r, level, decay * decay_scale) for r, level, decay in spec["parts"]]
    return partials(spec["base"] * ratio, parts, min(length, spec["length"]), 0.0015)


def wood_block(base=820.0, length=0.4, decay_scale=1.0):
    rng = random.Random(210)
    body = partials(base, [(1, 1.0, 0.045 * decay_scale), (2.3, 0.4, 0.02 * decay_scale)], length, 0.001)
    return [
        x + (rng.uniform(-1, 1) * 0.5 * math.exp(-i / RATE / 0.004) if i < RATE * 0.03 else 0.0)
        for i, x in enumerate(body)
    ]


def pulse_tone(ratio):
    """A soft swell and fall (no click) of the pulse: a sine and its octave."""
    spec = PULSE
    count = int(RATE * spec["length"])
    out = []
    for i in range(count):
        t = i / RATE
        envelope = math.sin(math.pi * min(1.0, t / spec["length"])) ** 2
        f = spec["base"] * ratio
        out.append((math.sin(2 * math.pi * f * t) + 0.5 * math.sin(4 * math.pi * f * t)) * envelope)
    return out


EXHALE = 2 / 3  # a fifth below the inhale tone

SOUNDS = {
    "soft-bell": {"inhale": lambda: tone(BELL, 1), "exhale": lambda: tone(BELL, EXHALE), "tick": lambda: tick(BELL, 2)},
    "singing-bowl": {
        "inhale": lambda: tone(BOWL, 1), "exhale": lambda: tone(BOWL, EXHALE), "tick": lambda: tick(BOWL, 2, 0.1, 0.4),
    },
    "chime": {"inhale": lambda: tone(CHIME, 1), "exhale": lambda: tone(CHIME, EXHALE), "tick": lambda: tick(CHIME, 1.5)},
    "wood-block": {
        "inhale": lambda: wood_block(), "exhale": lambda: wood_block(820 * EXHALE),
        "tick": lambda: wood_block(1400.0, 0.12, 0.5),
    },
    "pulse": {
        "inhale": lambda: pulse_tone(1), "exhale": lambda: pulse_tone(EXHALE),
        "tick": lambda: tick({**PULSE, "length": 0.2}, 2, 0.15, 0.2),
    },
}


def write_caf(name, samples, work):
    top = max(abs(x) for x in samples) or 1.0
    peak = PEAK * (0.7 if name.endswith("-tick") else 1.0)  # a tick is a little softer, it repeats
    fade = int(RATE * 0.02)  # the last 20 ms fade out, so a file never ends on a step
    pcm = []
    for i, x in enumerate(samples):
        gain = min(1.0, (len(samples) - i) / fade)
        pcm.append(int(round(x / top * peak * gain * 32767)))
    wav = work / f"{name}.wav"
    with wave.open(str(wav), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(struct.pack(f"<{len(pcm)}h", *pcm))
    OUT.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["afconvert", "-f", "caff", "-d", "LEI16@44100", "-c", "1", str(wav), str(OUT / f"{name}.caf")], check=True
    )


def main():
    if sys.platform != "darwin":
        sys.exit("afconvert is part of macOS: run this script on a Mac")
    with tempfile.TemporaryDirectory() as tmp:
        for sound, cues in SOUNDS.items():
            for cue, make in cues.items():
                name = f"{sound}-{cue}"
                write_caf(name, make(), Path(tmp))
                print(f"wrote {OUT / (name + '.caf')}")


if __name__ == "__main__":
    main()
