"""Generates every Project POP sound effect and the background music from
scratch (pure Python, no samples), so the audio is fully original and needs
no licence.

    python tools/make_sfx.py

Writes mono 16-bit WAV files to app/assets/sfx/ (effects, 44.1 kHz) and
app/assets/music/ (a seamless loop, 22.05 kHz).

Sound idea: the cheerful palette of casual mobile puzzle games -- bubbly
"bloop" pops, glockenspiel dings, a plucked ukulele and a whistled tune --
kept soft (no harsh clicks or buzz) with a little room reverb. Each step of a chain plays the next note of a major
pentatonic scale, so a long chain plays a little rising melody.
"""

import math
import os
import random
import struct
import wave

RATE = 44100
MUSIC_RATE = 22050
ROOT = os.path.join(os.path.dirname(__file__), "..", "app", "assets")
OUT = os.path.join(ROOT, "sfx")
MUSIC_OUT = os.path.join(ROOT, "music")
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


GLOCK = ((1, 1.0, 1.0), (2.76, 0.25, 0.4), (5.4, 0.08, 0.2), (8.93, 0.03, 0.1))


def chord(semis, dur, g=0.25, attack=0.02, decay=0.4, partials=None):
    return gain(mix(*[tone(note(s), dur, attack=attack, decay=decay, partials=partials or SOFT) for s in semis]), g)


def glock(semis, dur=0.9, decay=0.35, rate=RATE):
    return tone(note(semis + 12), dur, attack=0.002, decay=decay, partials=GLOCK, rate=rate)


def pluck(freq, dur, rate=RATE, damping=0.996, seed=1):
    """A plucked nylon string (Karplus-Strong): a burst of soft noise in a
    tuned, slowly damped delay line -- the ukulele of casual games."""
    rnd = random.Random(seed)
    period = max(2, int(rate / freq))
    buf = [rnd.uniform(-1, 1) for _ in range(period)]
    # Soften the pick so it doesn't click.
    for _ in range(2):
        buf = [(buf[i] + buf[i - 1]) / 2 for i in range(period)]
    n = int(dur * rate)
    out = [0.0] * n
    for i in range(n):
        k = i % period
        s = buf[k]
        out[i] = s
        buf[k] = damping * 0.5 * (s + buf[k - 1])
    fade = min(n, int(0.02 * rate))
    for i in range(fade):
        out[-1 - i] *= i / fade
    return out


def strum(shape, dur, rate=RATE, up=False, g=1.0):
    """Four strings, a few milliseconds apart (down or up)."""
    order = list(reversed(shape)) if up else list(shape)
    voices = [gain(pluck(note(s), dur, rate=rate, seed=s + 40), g * (0.8 if up else 1.0)) for s in order]
    return mix(*voices, offsets=[k * 0.011 for k in range(len(voices))], rate=rate)


def whistle(semis, dur, rate=RATE):
    """A soft whistled note: sine with a gentle scoop up and delayed vibrato."""
    f0 = note(semis)
    n = int(dur * rate)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / rate
        vib = 0.25 * min(1.0, max(0.0, (t - 0.12) / 0.15)) * math.sin(TAU * 5.5 * t)
        f = f0 * 2 ** ((vib - 1.0 * math.exp(-t / 0.03)) / 12)
        ph += TAU * f / rate
        e = min(1.0, t / 0.03) * min(1.0, (dur - t) / 0.06)
        out[i] = e * (math.sin(ph) + 0.06 * math.sin(2 * ph))
    return out


def kick(rate=RATE):
    n = int(0.22 * rate)
    out, ph = [0.0] * n, 0.0
    for i in range(n):
        t = i / rate
        ph += TAU * (48 + 90 * math.exp(-t / 0.03)) / rate
        out[i] = math.sin(ph) * math.exp(-t / 0.07)
    return out


def soft_noise(dur, cutoff, decay, rate=RATE, seed=3, highpass=0.0):
    rnd = random.Random(seed)
    n = int(dur * rate)
    a = 1 - math.exp(-TAU * cutoff / rate)
    out, y, prev = [0.0] * n, 0.0, 0.0
    for i in range(n):
        y += a * (rnd.uniform(-1, 1) - y)
        s = y - highpass * prev
        prev = y
        out[i] = s * math.exp(-(i / rate) / decay)
    return out


def clap(rate=RATE):
    hits = [soft_noise(0.12, 2200, 0.02 if k == 2 else 0.006, rate=rate, seed=10 + k, highpass=0.9) for k in range(3)]
    return mix(*hits, offsets=[0, 0.009, 0.018], rate=rate)


def shaker(rate=RATE, seed=0):
    return soft_noise(0.06, 9000, 0.012, rate=rate, seed=20 + seed, highpass=0.97)


def effects():
    os.makedirs(OUT, exist_ok=True)

    # Pops: the classic casual-game "bloop" (a bubble springing up in pitch)
    # topped with a glockenspiel ding on the chain's scale step.
    pentatonic = [0, 2, 4, 7, 9, 12, 14, 16]
    for step, semis in enumerate(pentatonic):
        f = note(semis - 12)
        bloop = tone(f, 0.12, attack=0.002, decay=0.035, partials=SOFT, bend=-12, bend_time=0.012)
        ding = gain(glock(semis, 0.6, decay=0.16), 0.45)
        save(f"pop_{step}", lowpass(mix(bloop, ding, offsets=[0, 0.018]), 9000), peak=0.62, room=0.15)

    # Landing: a soft little plucked "tock".
    save("land", lowpass(mix(gain(pluck(note(-17), 0.18, damping=0.97), 0.8),
                             tone(note(-12), 0.08, attack=0.002, decay=0.02, bend=-6, bend_time=0.01)), 3000),
         peak=0.36, room=0.08)

    # Shell bubble breaking: a bubble and a sparkly "ting-ting".
    bubble = tone(note(0), 0.1, attack=0.002, decay=0.03, bend=-12, bend_time=0.01)
    tings = [gain(glock(s, 0.6, decay=0.14), 0.7 - 0.15 * k) for k, s in enumerate((7, 12, 16))]
    save("crack", lowpass(mix(bubble, *tings, offsets=[0, 0.015, 0.06, 0.105]), 9000), peak=0.5, room=0.15)

    # A row rising: a soft airy swoosh up into a glock note.
    swoosh = gain(soft_noise(0.35, 1800, 0.12, seed=5, highpass=0.6), 0.25)
    slide = tone(note(-12), 0.3, attack=0.04, decay=0.1, partials=SOFT, bend=-10, bend_time=0.09)
    save("rise", lowpass(mix(swoosh, slide, gain(glock(7, 0.5, decay=0.12), 0.4), offsets=[0, 0, 0.16]), 6000),
         peak=0.4, room=0.15)

    # Rejected drop (full column): a friendly two-note "uh-uh" on a soft pluck.
    nope = mix(pluck(note(-13), 0.2, damping=0.98), pluck(note(-17), 0.28, damping=0.98), offsets=[0, 0.1])
    save("deny", lowpass(nope, 2500), peak=0.34, room=0.1)

    # UI tap: a tiny bubbly "blip".
    save("tap", tone(note(7), 0.07, attack=0.002, decay=0.016, partials=SOFT, bend=-9, bend_time=0.008),
         peak=0.32, room=0.06)

    # Praise: a glittering glock run.
    run = [gain(glock(s, 0.6, decay=0.15), 0.75) for s in (7, 12, 16, 19, 24)]
    save("praise", lowpass(mix(*run, offsets=[0, 0.05, 0.1, 0.15, 0.2]), 10000), peak=0.5, room=0.3)

    # Level up: a ukulele strum "ta-da" with a glock arpeggio on top.
    uke = mix(strum((-5, -12, -8, 0), 1.2, g=0.6), strum((-5, -12, -8, 0), 1.4, up=True, g=0.7), offsets=[0, 0.16])
    arp = [gain(glock(s, 0.7, decay=0.2), 0.6) for s in (0, 4, 7, 12)]
    save("levelup", lowpass(mix(uke, *arp, offsets=[0, 0.16, 0.24, 0.32, 0.4]), 9000), peak=0.55, room=0.25)

    # New best: a bouncy strummed C - F - G - C cadence with a glock fanfare.
    shapes = [(-5, -12, -8, 0), (-3, -12, -7, -3), (-5, -10, -5, -1), (-5, -12, -8, 0)]
    strums = [strum(s, 1.6 if k == 3 else 0.5, g=0.55) for k, s in enumerate(shapes)]
    fan = [gain(glock(s, 0.8, decay=0.22), 0.6) for s in (4, 5, 7, 12, 16, 19, 24)]
    offs = [0, 0.18, 0.36, 0.6] + [0.6 + 0.06 * k for k in range(7)]
    save("newbest", lowpass(mix(*strums, *fan, offsets=offs), 9000), peak=0.55, room=0.3)

    # Game over: a gentle, warm ending -- two soft strums and a falling glock line.
    end = mix(strum((-3, -12, -7, -3), 0.9, g=0.5), strum((-5, -12, -8, 0), 1.8, g=0.5), offsets=[0, 0.5])
    fall = [gain(glock(s, 0.8, decay=0.25), 0.4) for s in (12, 9, 7, 4)]
    save("gameover", lowpass(mix(end, *fall, offsets=[0, 0, 0.15, 0.3, 0.5]), 5000), peak=0.45, room=0.3)


def music():
    """A bouncy, sunny loop in the style of casual mobile puzzle games:
    strummed ukulele, glockenspiel and whistle melody, round bass, and a
    soft kick / clap / shaker groove, over C - Am - F - G."""
    os.makedirs(MUSIC_OUT, exist_ok=True)
    rate = MUSIC_RATE
    beat = 60 / 112
    bar = beat * 4
    # (bass root, ukulele shape), semitones from C5.
    C = (-24, (-5, -12, -8, 0))
    Am = (-27, (-5, -12, -8, -3))
    F = (-31, (-3, -12, -7, -3))
    G = (-29, (-5, -10, -5, -1))
    bars = [C, Am, F, G] * 4
    n = int(bar * len(bars) * rate)
    tail = int(3 * rate)
    out = [0.0] * (n + tail)

    def add(track, start_s, g):
        start = int(start_s * rate)
        for i, s in enumerate(track):
            j = start + i
            out[j - n if j >= n + tail else j] += s * g

    cache = {}

    def cached(key, make):
        if key not in cache:
            cache[key] = make()
        return cache[key]

    # Melody: (beat, semitones from C5, length in beats), one list per bar.
    tune = [
        [(0, 7, .5), (.5, 9, .5), (1, 12, 1), (2, 7, 1), (3, 4, 1)],
        [(0, 9, 1), (1, 7, .5), (1.5, 4, .5), (2, 0, 2)],
        [(0, 5, .5), (.5, 7, .5), (1, 9, 1), (2, 12, 1), (3, 9, 1)],
        [(0, 7, 1.5), (1.5, 5, .5), (2, 4, .5), (2.5, 2, .5), (3, 7, 1)],
        [(0, 12, .5), (.5, 11, .5), (1, 12, 1), (2, 16, 1), (3, 12, 1)],
        [(0, 9, 1), (1, 12, .5), (1.5, 9, .5), (2, 7, 2)],
        [(0, 5, .5), (.5, 9, .5), (1, 12, 1), (2, 14, 1), (3, 12, .5), (3.5, 9, .5)],
        [(0, 11, 1), (1, 7, 1), (2, 14, 2)],
    ]
    # Ukulele strum pattern: down, down-up, up-down-up (in beats).
    pattern = [(0, False), (1, False), (1.5, True), (2.5, True), (3, False), (3.5, True)]

    for k, (root, shape) in enumerate(bars):
        t0 = k * bar
        for b, up in pattern:
            add(cached(("strum", shape, up), lambda: strum(shape, 0.9, rate=rate, up=up)), t0 + b * beat,
                0.10 if b == 0 else 0.075)
        # Bass on 1 and 3, a pickup on the "and" of 4.
        add(cached(("bass", root), lambda: tone(note(root), 0.5, attack=0.004, decay=0.18, partials=SOFT, rate=rate)),
            t0, 0.36)
        add(cached(("bass", root), None), t0 + 2 * beat, 0.3)
        add(cached(("bass5", root), lambda: tone(note(root + 7), 0.3, attack=0.004, decay=0.1, partials=SOFT,
                                                   rate=rate)), t0 + 3.5 * beat, 0.2)
        # Drums: kick on 1 and 3, clap on 2 and 4, shaker on the eighths.
        for b in (0, 2):
            add(cached("kick", lambda: kick(rate)), t0 + b * beat, 0.32)
        for b in (1, 3):
            add(cached("clap", lambda: clap(rate)), t0 + b * beat, 0.12)
        for e in range(8):
            add(cached(("shaker", e % 2), lambda: shaker(rate, e % 2)), t0 + e * beat / 2, 0.05 if e % 2 else 0.03)
        # Melody: glockenspiel first time round, whistle (with a quiet glock)
        # the second.
        second = k >= 8
        for b, s, d in tune[k % 8]:
            add(cached(("glock", s), lambda: glock(s, 1.0, decay=0.3, rate=rate)), t0 + b * beat,
                0.09 if second else 0.17)
            if second:
                add(cached(("whistle", s, d), lambda: whistle(s, d * beat * 0.95, rate=rate)), t0 + b * beat, 0.13)

    # Wrap the overflow into the start so the loop is seamless.
    for i in range(tail):
        out[i] += out[n + i]
    track = out[:n]
    track = lowpass(track + track[: int(2.0 * rate)], 7000, rate)
    track = reverb(track, wet=0.3, size=1.2, tail=0, rate=rate)
    # The reverbed copy of the first 2 s is folded back so the loop stays seamless.
    head = track[n:]
    track = track[:n]
    for i, s in enumerate(head):
        w = i / len(head)
        track[i] = track[i] * w + s * (1 - w)
    m = max(abs(s) for s in track)
    write_wav(os.path.join(MUSIC_OUT, "theme.wav"), [s * 0.75 / m for s in track], rate)


if __name__ == "__main__":
    effects()
    music()
