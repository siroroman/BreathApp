#!/usr/bin/env python3
"""Synthesises the five Session sounds into App/Breathnest/Sounds/<sound-id>.caf (#210, decisions in #49).

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


def soft_bell():
    return partials(523.25, [(1, 1.0, 0.9), (2.76, 0.45, 0.5), (5.4, 0.2, 0.3), (8.93, 0.08, 0.15)], 3.0, 0.004)


def singing_bowl():
    # Pairs a few cents apart beat slowly, which gives the bowl its slow shimmer.
    parts = [(1, 1.0, 2.2), (1.004, 0.8, 2.0), (2.71, 0.4, 1.4), (2.72, 0.35, 1.3), (5.12, 0.15, 0.8)]
    return partials(220.0, parts, 4.5, 0.06)


def chime():
    return partials(1318.5, [(1, 1.0, 0.7), (2.0, 0.35, 0.4), (3.01, 0.2, 0.25), (4.2, 0.08, 0.12)], 2.5, 0.002)


def wood_block():
    rng = random.Random(210)
    body = partials(820.0, [(1, 1.0, 0.045), (2.3, 0.4, 0.02)], 0.4, 0.001)
    return [x + (rng.uniform(-1, 1) * 0.5 * math.exp(-i / RATE / 0.004) if i < RATE * 0.03 else 0.0) for i, x in enumerate(body)]


def pulse():
    count = int(RATE * 0.7)
    out = []
    for i in range(count):
        t = i / RATE
        envelope = math.sin(math.pi * min(1.0, t / 0.7)) ** 2  # a soft swell and fall, no click
        out.append(math.sin(2 * math.pi * 98.0 * t) * envelope)
    return out


SOUNDS = {
    "soft-bell": soft_bell,
    "singing-bowl": singing_bowl,
    "chime": chime,
    "wood-block": wood_block,
    "pulse": pulse,
}


def write_caf(name, samples, work):
    top = max(abs(x) for x in samples) or 1.0
    fade = int(RATE * 0.02)  # the last 20 ms fade out, so a file never ends on a step
    pcm = []
    for i, x in enumerate(samples):
        gain = min(1.0, (len(samples) - i) / fade)
        pcm.append(int(round(x / top * PEAK * gain * 32767)))
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
        for name, make in SOUNDS.items():
            write_caf(name, make(), Path(tmp))
            print(f"wrote {OUT / (name + '.caf')}")


if __name__ == "__main__":
    main()
