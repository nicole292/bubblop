"""Generates every Project POP sound effect and the background music from
scratch (pure Python, no samples), so the audio is fully original and needs
no licence.

    python tools/make_sfx.py

Writes mono 16-bit WAV files to app/assets/sfx/ (effects, 44.1 kHz) and
app/assets/music/ (a seamless loop, 22.05 kHz).

Sound idea: light and soft -- water-droplet plips, music-box dings, kalimba
and a whistled tune. Only smooth, rounded tones (no noise, clicks, drums or
buzz), kept quiet enough that overlapping sounds never distort. Each step of a chain plays the next note of a major
pentatonic scale, so a long chain plays a little rising melody.
"""

import math
import os
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


def whistle(semis, dur, rate=RATE):
    """A soft whistled note: sine with a gentle scoop up and delayed vibrato."""
    f0 = note(semis)
    n = int(dur * rate)
    out = [0.0] * n
    ph = 0.0
    for i in range(n):
        t = i / rate
        vib = 0.2 * min(1.0, max(0.0, (t - 0.15) / 0.2)) * math.sin(TAU * 5.2 * t)
        f = f0 * 2 ** ((vib - 0.7 * math.exp(-t / 0.035)) / 12)
        ph += TAU * f / rate
        e = min(1.0, t / 0.05) * min(1.0, (dur - t) / 0.08)
        out[i] = e * math.sin(ph)
    return out


def droplet(semis, dur=0.2, rise=7, rise_time=0.03, decay=0.05):
    """A water droplet "plip": a pure tone that springs up in pitch."""
    return tone(note(semis), dur, attack=0.004, decay=decay, partials=((1, 1.0, 1.0),), bend=-rise,
                bend_time=rise_time)


def effects():
    os.makedirs(OUT, exist_ok=True)

    # Pops: a soft bubbly droplet with a light music-box ding on the chain's
    # scale step.
    pentatonic = [0, 2, 4, 7, 9, 12, 14, 16]
    for step, semis in enumerate(pentatonic):
        plip = droplet(semis - 12, 0.15, rise=9, rise_time=0.02, decay=0.04)
        ding = gain(glock(semis, 0.7, decay=0.18), 0.5)
        save(f"pop_{step}", lowpass(mix(plip, ding, offsets=[0, 0.02]), 5000), peak=0.42, room=0.2)

    # Dropping a ball in: a tiny, gentle water-drop "plip".
    save("land", lowpass(droplet(5, 0.14, rise=6, rise_time=0.025, decay=0.035), 3000), peak=0.24, room=0.12)

    # Shell bubble breaking: a soft droplet and two light dings.
    tings = [gain(glock(s, 0.7, decay=0.16), 0.55 - 0.15 * k) for k, s in enumerate((12, 16))]
    save("crack", lowpass(mix(droplet(0, 0.15), *tings, offsets=[0, 0.03, 0.08]), 5000), peak=0.36, room=0.2)

    # A row rising: a soft upward hum into a kalimba note.
    slide = tone(note(-12), 0.35, attack=0.06, decay=0.12, partials=((1, 1.0, 1.0),), bend=-7, bend_time=0.1)
    save("rise", lowpass(mix(gain(slide, 0.7), gain(kalimba(7, 0.6, decay=0.14), 0.5), offsets=[0, 0.16]), 3500),
         peak=0.3, room=0.2)

    # Rejected drop (full column): two soft kalimba notes, falling.
    nope = mix(kalimba(-1, 0.3, decay=0.06), kalimba(-5, 0.35, decay=0.08), offsets=[0, 0.11])
    save("deny", lowpass(nope, 2500), peak=0.26, room=0.12)

    # UI tap: the lightest little droplet.
    save("tap", lowpass(droplet(12, 0.08, rise=5, rise_time=0.012, decay=0.018), 4000), peak=0.22, room=0.08)

    # Praise: a light music-box run.
    run = [gain(glock(s, 0.7, decay=0.18), 0.7) for s in (7, 12, 16, 19)]
    save("praise", lowpass(mix(*run, offsets=[0, 0.06, 0.12, 0.18]), 6000), peak=0.38, room=0.3)

    # Level up: a kalimba arpeggio blooming into a soft chord.
    arp = [kalimba(s, 0.8, decay=0.25) for s in (0, 4, 7, 12)]
    bloom = chord((0, 4, 7), 1.2, g=0.3, attack=0.08, decay=0.4)
    sparkle = [gain(glock(s, 0.6, decay=0.2), 0.3) for s in (12, 16, 19)]
    save("levelup", lowpass(mix(*arp, bloom, *sparkle, offsets=[0, 0.08, 0.16, 0.24, 0.24, 0.34, 0.4, 0.46]), 5500),
         peak=0.42, room=0.3)

    # New best: a happy kalimba run with a music-box sparkle, settling on a
    # warm chord.
    notes = (0, 4, 7, 12, 16, 19)
    run = [kalimba(s, 0.6, decay=0.18) for s in notes]
    sparkle = [gain(glock(s, 0.8, decay=0.25), 0.4) for s in (12, 16, 19, 24)]
    warm = chord((-12, 0, 4, 7), 1.8, g=0.35, attack=0.1, decay=0.6)
    offs = [0.08 * k for k in range(len(notes))] + [0.5 + 0.07 * k for k in range(4)] + [0.48]
    save("newbest", lowpass(mix(*run, *sparkle, warm, offsets=offs), 5500), peak=0.45, room=0.35)

    # Game over: gentle and warm -- a soft falling kalimba line onto a chord.
    down = [kalimba(s, 0.8, decay=0.22) for s in (12, 7, 4)]
    rest = chord((-12, -5, 0, 4), 1.8, g=0.3, attack=0.08, decay=0.6)
    save("gameover", lowpass(mix(*down, rest, offsets=[0, 0.2, 0.4, 0.6]), 3500), peak=0.36, room=0.35)


def music():
    """A light, sunny, gently bouncing loop: kalimba chords, a round soft
    bass, and a music-box melody that a soft whistle joins the second time
    round, over C - Am - F - G. No drums or noise, so it stays smooth."""
    os.makedirs(MUSIC_OUT, exist_ok=True)
    rate = MUSIC_RATE
    beat = 60 / 104
    bar = beat * 4
    # (bass root, chord tones), semitones from C5.
    C = (-24, (-12, -8, -5))
    Am = (-27, (-15, -12, -8))
    F = (-31, (-17, -12, -8))
    G = (-29, (-17, -13, -10))
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

    for k, (root, tones) in enumerate(bars):
        t0 = k * bar
        # Kalimba: a light, bouncing broken chord on the eighths.
        pattern = [tones[0], tones[2], tones[1] + 12, tones[2], tones[0] + 12, tones[2], tones[1] + 12, tones[2]]
        for e, s in enumerate(pattern):
            add(cached(("kal", s), lambda: kalimba(s, 0.7, decay=0.16, rate=rate)), t0 + e * beat / 2,
                0.12 if e % 2 == 0 else 0.08)
        # A soft, warm bed of the chord, held through the bar.
        add(cached(("bed", tones), lambda: chord(tones, bar + 0.6, g=0.06, attack=0.25, decay=1.6, rate=rate)),
            t0, 1.0)
        # Bass on 1 and 3.
        b = cached(("bass", root), lambda: tone(note(root), 0.8, attack=0.01, decay=0.3, partials=SOFT, rate=rate))
        add(b, t0, 0.3)
        add(b, t0 + 2 * beat, 0.24)
        # Melody: music box first time round, whistle with a quieter music
        # box the second.
        second = k >= 8
        for bt, s, d in tune[k % 8]:
            add(cached(("glock", s), lambda: glock(s, 1.0, decay=0.3, rate=rate)), t0 + bt * beat,
                0.08 if second else 0.15)
            if second:
                add(cached(("whistle", s, d), lambda: whistle(s, d * beat * 0.95, rate=rate)), t0 + bt * beat, 0.1)

    # Wrap the overflow into the start so the loop is seamless.
    for i in range(tail):
        out[i] += out[n + i]
    track = out[:n]
    track = lowpass(track + track[: int(2.0 * rate)], 4500, rate)
    track = reverb(track, wet=0.35, size=1.3, tail=0, rate=rate)
    # The reverbed copy of the first 2 s is folded back so the loop stays seamless.
    head = track[n:]
    track = track[:n]
    for i, s in enumerate(head):
        w = i / len(head)
        track[i] = track[i] * w + s * (1 - w)
    m = max(abs(s) for s in track)
    write_wav(os.path.join(MUSIC_OUT, "theme.wav"), [s * 0.7 / m for s in track], rate)


if __name__ == "__main__":
    effects()
    music()
