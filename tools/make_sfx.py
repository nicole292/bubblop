"""Generates every Project POP sound effect from scratch (pure Python, no
samples), so the audio is fully original and needs no licence.

    python tools/make_sfx.py

Writes 44.1 kHz mono 16-bit WAV files to app/assets/sfx/.

Signature idea: each step of a chain plays the next note of a major
pentatonic scale, so a long chain plays a little rising melody.
"""

import math
import os
import random
import struct
import wave

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "app", "assets", "sfx")
random.seed(42)


def env_adsr(t, attack, decay_time, total):
    """Fast attack, exponential decay; 0 after total."""
    if t < attack:
        return t / attack
    if t > total:
        return 0.0
    return math.exp(-(t - attack) / decay_time)


def tone(freq_start, freq_end, dur, attack=0.004, decay=0.05, harmonics=(1.0,), glide=8.0):
    """A pitched blip whose frequency glides from start to end."""
    n = int(RATE * dur)
    phase = [0.0] * len(harmonics)
    out = []
    for i in range(n):
        t = i / RATE
        k = 1 - math.exp(-t * glide)
        f = freq_start + (freq_end - freq_start) * k
        s = 0.0
        for h, amp in enumerate(harmonics):
            phase[h] += 2 * math.pi * f * (h + 1) / RATE
            s += amp * math.sin(phase[h])
        out.append(s * env_adsr(t, attack, decay, dur))
    return out


def noise(dur, decay=0.02, lowpass=0.5):
    """A short filtered noise click."""
    n = int(RATE * dur)
    out, prev = [], 0.0
    for i in range(n):
        t = i / RATE
        prev = prev + lowpass * (random.uniform(-1, 1) - prev)
        out.append(prev * math.exp(-t / decay))
    return out


def mix(*tracks, offsets=None):
    offsets = offsets or [0.0] * len(tracks)
    length = max(int(o * RATE) + len(tr) for tr, o in zip(tracks, offsets))
    out = [0.0] * length
    for tr, o in zip(tracks, offsets):
        start = int(o * RATE)
        for i, s in enumerate(tr):
            out[start + i] += s
    return out


def gain(track, g):
    return [s * g for s in track]


def save(name, track, peak=0.8):
    m = max(1e-9, max(abs(s) for s in track))
    scale = peak / m
    # 3 ms fade-out avoids clicks at the end.
    fade = int(0.003 * RATE)
    for i in range(min(fade, len(track))):
        track[-1 - i] *= i / fade
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in track))
    print("wrote", os.path.relpath(path))


def note(semitones_from_c5):
    return 523.25 * 2 ** (semitones_from_c5 / 12)


def main():
    os.makedirs(OUT, exist_ok=True)

    # Pops: a bubbly blip (pitch drops slightly) plus a soft click, one per
    # chain step on a major pentatonic scale starting at C5.
    pentatonic = [0, 2, 4, 7, 9, 12, 14, 16]
    for step, semis in enumerate(pentatonic):
        f = note(semis)
        body = tone(f * 1.25, f, 0.22, decay=0.07, harmonics=(1.0, 0.35, 0.12), glide=40)
        click = gain(noise(0.03, decay=0.006, lowpass=0.6), 0.35)
        sparkle = gain(tone(f * 2, f * 2, 0.12, decay=0.04, harmonics=(1.0,)), 0.18)
        save(f"pop_{step}", mix(body, click, sparkle, offsets=[0, 0, 0.012]), peak=0.75)

    # Landing: a soft, low "tok".
    save("land", mix(tone(260, 150, 0.09, decay=0.025, harmonics=(1.0, 0.2), glide=60),
                     gain(noise(0.02, decay=0.004, lowpass=0.3), 0.3)), peak=0.45)

    # Shell bubble breaking: a glassy plink and a wet bubble pop.
    plink = tone(2350, 2200, 0.16, decay=0.05, harmonics=(1.0, 0.3))
    bubble = tone(420, 900, 0.07, decay=0.02, harmonics=(1.0,), glide=50)
    save("crack", mix(plink, gain(bubble, 0.8), gain(noise(0.04, decay=0.008, lowpass=0.8), 0.4)), peak=0.6)

    # A row rising: a soft upward whoomp.
    rise = tone(140, 280, 0.32, attack=0.03, decay=0.12, harmonics=(1.0, 0.5, 0.2), glide=6)
    save("rise", mix(rise, gain(noise(0.25, decay=0.08, lowpass=0.08), 0.5)), peak=0.5)

    # Rejected drop (full column): a short low buzz.
    save("deny", tone(160, 120, 0.12, decay=0.05, harmonics=(1.0, 0.6, 0.4, 0.3)), peak=0.35)

    # UI tap.
    save("tap", mix(tone(1200, 900, 0.05, decay=0.012), gain(noise(0.01, decay=0.002), 0.2)), peak=0.4)

    # Praise sparkle: a quick rising shimmer.
    shimmer = [tone(note(s), note(s), 0.18, decay=0.06, harmonics=(1.0, 0.25)) for s in (12, 16, 19, 24)]
    save("praise", mix(*shimmer, offsets=[0, 0.04, 0.08, 0.12]), peak=0.55)

    # Level up: a bright arpeggio.
    arp = [tone(note(s), note(s), 0.25, decay=0.09, harmonics=(1.0, 0.3, 0.1)) for s in (0, 4, 7, 12)]
    save("levelup", mix(*arp, offsets=[0, 0.07, 0.14, 0.21]), peak=0.6)

    # New best: a longer, happier fanfare.
    fan = [tone(note(s), note(s), 0.35, decay=0.14, harmonics=(1.0, 0.35, 0.12)) for s in (0, 4, 7, 12, 16, 19, 24)]
    save("newbest", mix(*fan, offsets=[0, 0.06, 0.12, 0.18, 0.26, 0.34, 0.42]), peak=0.6)

    # Game over: gentle and descending (not punishing).
    down = [tone(note(s), note(s), 0.4, decay=0.16, harmonics=(1.0, 0.25)) for s in (7, 4, 0, -5)]
    save("gameover", mix(*down, offsets=[0, 0.12, 0.24, 0.36]), peak=0.5)


if __name__ == "__main__":
    main()
