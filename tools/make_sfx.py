"""Generates every Project POP sound effect from scratch (pure Python, no
samples), so the effects are fully original and need no licence. The music
is a recorded track instead (see README.md).

    python tools/make_sfx.py

Writes mono 16-bit, 44.1 kHz WAV files to app/assets/sfx/.

Sound idea: light and soft -- water-droplet plips, music-box dings and
kalimba. Only smooth, rounded tones (no noise, clicks, drums or
buzz), kept quiet enough that overlapping sounds never distort. Each step of a chain plays the next note of a major
pentatonic scale, so a long chain plays a little rising melody.
"""

import math
import os
import struct
import wave

RATE = 44100
ROOT = os.path.join(os.path.dirname(__file__), "..", "app", "assets")
OUT = os.path.join(ROOT, "sfx")
TAU = 2 * math.pi


def env(t, attack, decay):
    """Smooth (raised-cosine) attack, then exponential decay."""
    if t < attack:
        return 0.5 - 0.5 * math.cos(math.pi * t / attack)
    return math.exp(-(t - attack) / decay)


def tone(freq, dur, attack=0.006, decay=0.08, partials=((1, 1.0, 1.0),), bend=0.0, bend_time=0.02, rate=RATE):
    """A soft pitched note. Each partial is (ratio, amplitude, decay scale),
    so upper partials can fade faster than the body, like a mallet or bell.
    `bend` starts the pitch that many semitones off and settles it quickly."""
    n = int(rate * dur)
    phases = [0.0] * len(partials)
    out = [0.0] * n
    for i in range(n):
        t = i / rate
        f = freq * 2 ** (bend * math.exp(-t / bend_time) / 12) if bend else freq
        s = 0.0
        for p, (ratio, amp, dscale) in enumerate(partials):
            phases[p] += TAU * f * ratio / rate
            s += amp * math.sin(phases[p]) * env(t, attack, decay * dscale)
        out[i] = s
    return out


# Timbres.
MARIMBA = ((1, 1.0, 1.0), (4, 0.18, 0.25), (10, 0.04, 0.1))
BELL = ((1, 1.0, 1.0), (2, 0.22, 0.6), (3.01, 0.08, 0.35), (5.4, 0.03, 0.2))
SOFT = ((1, 1.0, 1.0), (2, 0.12, 0.5))


def lowpass(track, cutoff, rate=RATE):
    a = 1 - math.exp(-TAU * cutoff / rate)
    out, y = [], 0.0
    for s in track:
        y += a * (s - y)
        out.append(y)
    return out


def reverb(track, wet=0.22, size=1.0, tail=0.35, rate=RATE):
    """A small, warm room: parallel damped combs into two allpasses."""
    track = track + [0.0] * int(tail * rate)
    n = len(track)
    acc = [0.0] * n
    for delay_ms, fb in ((29.7, 0.72), (37.1, 0.7), (41.1, 0.68), (43.7, 0.66)):
        d = max(1, int(delay_ms * size * rate / 1000))
        buf = [0.0] * n
        damp = 0.0
        for i in range(n):
            back = buf[i - d] if i >= d else 0.0
            damp += 0.45 * (back - damp)
            buf[i] = track[i] + damp * fb
            acc[i] += back
    for delay_ms in (5.0, 1.7):
        d = max(1, int(delay_ms * rate / 1000))
        g = 0.6
        out = [0.0] * n
        for i in range(n):
            prev_in = acc[i - d] if i >= d else 0.0
            prev_out = out[i - d] if i >= d else 0.0
            out[i] = -g * acc[i] + prev_in + g * prev_out
        acc = out
    return [dry + wet * 0.25 * w for dry, w in zip(track, acc)]


def mix(*tracks, offsets=None, rate=RATE):
    offsets = offsets or [0.0] * len(tracks)
    length = max(int(o * rate) + len(tr) for tr, o in zip(tracks, offsets))
    out = [0.0] * length
    for tr, o in zip(tracks, offsets):
        start = int(o * rate)
        for i, s in enumerate(tr):
            out[start + i] += s
    return out


def gain(track, g):
    return [s * g for s in track]


def write_wav(path, track, rate):
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in track))
    print("wrote", os.path.relpath(path))


def save(name, track, peak=0.7, room=0.22):
    track = reverb(track, wet=room) if room else track
    m = max(1e-9, max(abs(s) for s in track))
    track = [s * peak / m for s in track]
    # Trim the silent end of the reverb tail, then fade out to avoid clicks.
    while len(track) > RATE // 10 and abs(track[-1]) < 1e-4:
        track.pop()
    fade = min(len(track), int(0.03 * RATE))
    for i in range(fade):
        track[-1 - i] *= (i / fade) ** 2
    write_wav(os.path.join(OUT, name + ".wav"), track, RATE)


def note(semitones_from_c5):
    return 523.25 * 2 ** (semitones_from_c5 / 12)


# A soft music box / glockenspiel: bright but gentle upper partials.
GLOCK = ((1, 1.0, 1.0), (2.76, 0.12, 0.35), (5.4, 0.03, 0.15))
# A kalimba: round body, a faint, quickly fading overtone.
KALIMBA = ((1, 1.0, 1.0), (3, 0.08, 0.25), (5.1, 0.02, 0.1))


def chord(semis, dur, g=0.25, attack=0.02, decay=0.4, partials=None, rate=RATE):
    return gain(mix(*[tone(note(s), dur, attack=attack, decay=decay, partials=partials or SOFT, rate=rate)
                      for s in semis], rate=rate), g)


def glock(semis, dur=0.9, decay=0.3, rate=RATE):
    return tone(note(semis + 12), dur, attack=0.006, decay=decay, partials=GLOCK, rate=rate)


def kalimba(semis, dur=0.8, decay=0.22, rate=RATE):
    return tone(note(semis), dur, attack=0.006, decay=decay, partials=KALIMBA, rate=rate)


def droplet(semis, dur=0.2, rise=7, rise_time=0.03, decay=0.05):
    """A water droplet "plip": a pure tone that springs up in pitch."""
    return tone(note(semis), dur, attack=0.004, decay=decay, partials=((1, 1.0, 1.0),), bend=-rise,
                bend_time=rise_time)


def effects():
    os.makedirs(OUT, exist_ok=True)

    # Pops: the same light droplet as the UI tap, a touch longer, on the
    # chain's scale step.
    pentatonic = [0, 2, 4, 7, 9, 12, 14, 16]
    for step, semis in enumerate(pentatonic):
        save(f"pop_{step}", lowpass(droplet(semis + 5, 0.1, rise=5, rise_time=0.012, decay=0.024), 4000),
             peak=0.24, room=0.1)

    # Dropping a ball in: a tiny, gentle water-drop "plip".
    save("land", lowpass(droplet(5, 0.14, rise=6, rise_time=0.025, decay=0.035), 3000), peak=0.24, room=0.12)

    # Shell bubble breaking: the drop "plip", a little higher, and one soft ding.
    save("crack", lowpass(mix(droplet(9, 0.14, rise=6, rise_time=0.025, decay=0.035),
                              gain(glock(12, 0.7, decay=0.16), 0.35), offsets=[0, 0.04]), 4000),
         peak=0.26, room=0.2)

    # A row rising: two soft kalimba notes stepping up.
    save("rise", lowpass(mix(kalimba(-5, 0.6, decay=0.14), gain(kalimba(0, 0.7, decay=0.16), 0.8),
                             offsets=[0, 0.12]), 2800), peak=0.22, room=0.2)

    # Rejected drop (full column): one soft, low kalimba note.
    save("deny", lowpass(kalimba(-8, 0.4, decay=0.08), 2200), peak=0.2, room=0.12)

    # UI tap: the lightest little droplet.
    save("tap", lowpass(droplet(12, 0.08, rise=5, rise_time=0.012, decay=0.018), 4000), peak=0.2, room=0.08)

    # Praise: three light music-box notes.
    run = [glock(s, 0.7, decay=0.18) for s in (7, 12, 16)]
    save("praise", lowpass(mix(*run, offsets=[0, 0.08, 0.16]), 4500), peak=0.3, room=0.3)

    # Level up: a soft kalimba arpeggio over a quiet chord.
    arp = [kalimba(s, 0.8, decay=0.22) for s in (0, 4, 7, 12)]
    bed = chord((-12, -5, 4), 1.2, g=0.2, attack=0.1, decay=0.5)
    save("levelup", lowpass(mix(*arp, bed, offsets=[0, 0.1, 0.2, 0.3, 0.1]), 4000), peak=0.34, room=0.3)

    # New best: a longer kalimba run with a music-box twinkle on a warm chord.
    notes = (0, 4, 7, 12, 16)
    run = [kalimba(s, 0.7, decay=0.2) for s in notes]
    twinkle = [gain(glock(s, 0.8, decay=0.22), 0.3) for s in (12, 19)]
    warm = chord((-12, 0, 4, 7), 1.8, g=0.25, attack=0.15, decay=0.6)
    offs = [0.1 * k for k in range(len(notes))] + [0.55, 0.65, 0.45]
    save("newbest", lowpass(mix(*run, *twinkle, warm, offsets=offs), 4000), peak=0.36, room=0.35)

    # Game over: gentle and warm -- a soft falling kalimba line onto a chord.
    down = [kalimba(s, 0.8, decay=0.22) for s in (7, 4, 0)]
    rest = chord((-12, -5, 0, 4), 1.8, g=0.22, attack=0.12, decay=0.6)
    save("gameover", lowpass(mix(*down, rest, offsets=[0, 0.22, 0.44, 0.6]), 3000), peak=0.3, room=0.35)


if __name__ == "__main__":
    effects()
