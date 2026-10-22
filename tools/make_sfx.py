"""Generates every Project POP sound effect and the background music from
scratch (pure Python, no samples), so the audio is fully original and needs
no licence.

    python tools/make_sfx.py

Writes mono 16-bit WAV files to app/assets/sfx/ (effects, 44.1 kHz) and
app/assets/music/ (a seamless loop, 22.05 kHz).

Sound idea: soft, rounded tones only -- sine bodies with gentle bell
partials, no noise bursts or buzzy harmonics, and a little room reverb so
nothing ends abruptly. Each step of a chain plays the next note of a major
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


def chord(semis, dur, g=0.25, attack=0.02, decay=0.4, partials=None):
    return gain(mix(*[tone(note(s), dur, attack=attack, decay=decay, partials=partials or SOFT) for s in semis]), g)


def effects():
    os.makedirs(OUT, exist_ok=True)

    # Pops: a bright, bubbly marimba "bloop" (pitch springs up into the note)
    # with a twinkle an octave and a fifth above.
    pentatonic = [0, 2, 4, 7, 9, 12, 14, 16]
    for step, semis in enumerate(pentatonic):
        f = note(semis)
        body = tone(f, 0.4, attack=0.003, decay=0.09, partials=MARIMBA, bend=-6, bend_time=0.014)
        twinkle = gain(tone(f * 3, 0.3, attack=0.005, decay=0.06, partials=BELL), 0.12)
        save(f"pop_{step}", lowpass(mix(body, twinkle, offsets=[0, 0.025]), 7000), peak=0.62)

    # Landing: a soft, round "boop".
    save("land", tone(note(-5), 0.16, attack=0.003, decay=0.04, partials=((1, 1.0, 1.0), (2, 0.15, 0.4)),
                      bend=-4, bend_time=0.012), peak=0.36, room=0.1)

    # Shell bubble breaking: a sparkly upward "ting-ting-ting".
    tings = [gain(tone(note(s), 0.45, decay=0.1, partials=BELL), 0.9 - 0.15 * k)
             for k, s in enumerate((19, 24, 28))]
    bubble = gain(tone(note(7), 0.1, attack=0.003, decay=0.025, bend=-9, bend_time=0.012), 0.6)
    save("crack", lowpass(mix(bubble, *tings, offsets=[0, 0.01, 0.05, 0.09]), 8000), peak=0.48)

    # A row rising: a cheerful upward slide into a little chime.
    slide = tone(note(-5), 0.3, attack=0.03, decay=0.12, partials=SOFT, bend=-7, bend_time=0.08)
    chime = gain(tone(note(12), 0.4, decay=0.1, partials=BELL), 0.5)
    save("rise", mix(slide, chime, offsets=[0, 0.12]), peak=0.42)

    # Rejected drop (full column): two soft falling notes, a friendly "uh-uh".
    nope = mix(tone(note(-1), 0.16, decay=0.045, partials=MARIMBA),
               tone(note(-5), 0.22, decay=0.06, partials=MARIMBA), offsets=[0, 0.1])
    save("deny", lowpass(nope, 3000), peak=0.32, room=0.12)

    # UI tap: a tiny bubbly "pip".
    save("tap", lowpass(tone(note(12), 0.09, attack=0.002, decay=0.018, partials=MARIMBA, bend=-5, bend_time=0.008),
                        6000), peak=0.32, room=0.08)

    # Praise: a quick sparkling run up to a bright little chord.
    run = [gain(tone(note(s), 0.4, decay=0.09, partials=BELL), 0.75) for s in (12, 14, 16, 19, 21)]
    top = chord((24, 28, 31), 0.8, g=0.45, attack=0.005, decay=0.2, partials=BELL)
    save("praise", lowpass(mix(*run, top, offsets=[0, 0.045, 0.09, 0.135, 0.18, 0.23]), 8000), peak=0.5, room=0.3)

    # Level up: "ta-da!" -- two quick pickup notes, then a bright major chord.
    pick = [tone(note(s), 0.3, decay=0.08, partials=MARIMBA) for s in (7, 11)]
    tada = mix(chord((0, 4, 7, 12), 1.0, g=0.5, attack=0.005, decay=0.3, partials=BELL),
               chord((-12, -5), 1.0, g=0.4, attack=0.01, decay=0.35))
    sparkle = [gain(tone(note(s), 0.3, decay=0.07, partials=BELL), 0.35) for s in (24, 28, 31, 36)]
    save("levelup", lowpass(mix(*pick, tada, *sparkle, offsets=[0, 0.09, 0.18, 0.3, 0.36, 0.42, 0.48]), 8000),
         peak=0.55, room=0.3)

    # New best: a happy fanfare that climbs, trills and lands on a big chord.
    notes = (0, 4, 7, 12, 7, 12, 16, 19)
    run = [tone(note(s), 0.35, decay=0.1, partials=MARIMBA) for s in notes]
    trill = [gain(tone(note(s), 0.2, decay=0.05, partials=BELL), 0.5) for s in (24, 26, 24, 26, 24)]
    final = mix(chord((12, 16, 19, 24), 1.6, g=0.6, attack=0.005, decay=0.45, partials=BELL),
                chord((-12, -5, 0), 1.6, g=0.4, attack=0.02, decay=0.5))
    offs = [0.08 * k for k in range(len(notes))] + [0.66 + 0.05 * k for k in range(5)] + [0.92]
    save("newbest", lowpass(mix(*run, *trill, final, offsets=offs), 8000), peak=0.55, room=0.35)

    # Game over: gentle and warm, never sad -- a little descent that lands
    # on a soft major chord.
    down = [tone(note(s), 0.6, decay=0.16, partials=MARIMBA) for s in (12, 7, 4)]
    rest = chord((-12, -5, 0, 4, 7), 1.6, g=0.35, attack=0.04, decay=0.5)
    save("gameover", lowpass(mix(*down, rest, offsets=[0, 0.18, 0.36, 0.54]), 4500), peak=0.45, room=0.35)


def music():
    """A light, happy, seamlessly looping tune at an easy-going tempo:
    soft pads, a bouncing marimba arpeggio, a round bass and a music-box
    melody over C - G - Am - F."""
    os.makedirs(MUSIC_OUT, exist_ok=True)
    rate = MUSIC_RATE
    beat = 60 / 100
    bar = beat * 4
    # Chord roots and chord tones (semitones from C5), one chord per bar.
    C, G, Am, F = (0, (0, 4, 7)), (-5, (-5, -1, 2)), (-3, (-3, 0, 4)), (-7, (-7, -3, 0))
    bars = [C, G, Am, F, C, G, F, G] * 2
    n = int(bar * len(bars) * rate)
    tail = int(4 * rate)
    out = [0.0] * (n + tail)

    def add(track, start_s, g):
        start = int(start_s * rate)
        for i, s in enumerate(track):
            j = start + i
            out[j - n if j >= n + tail else j] += s * g

    def pad_voice(freq, dur):
        m = int(dur * rate)
        res = [0.0] * m
        p1 = p2 = 0.0
        for i in range(m):
            e = math.sin(math.pi * i / m) ** 2
            p1 += TAU * freq / rate
            p2 += TAU * freq * 1.004 / rate
            res[i] = e * (math.sin(p1) + 0.5 * math.sin(p2))
        return res

    cache = {}

    def pluck(semis, dur, partials, decay):
        key = (semis, dur, partials, decay)
        if key not in cache:
            cache[key] = tone(note(semis), dur, attack=0.004, decay=decay, partials=partials, rate=rate)
        return cache[key]

    # Melody: (beat, semitones from C5, length in beats), one list per bar.
    tune = [
        [(0, 4, 1), (1, 7, 1), (2, 12, 1.5), (3.5, 7, 0.5)],
        [(0, 14, 1), (1, 11, 1), (2, 7, 2)],
        [(0, 12, 1), (1, 9, 1), (2, 4, 1), (3, 7, 1)],
        [(0, 9, 1.5), (1.5, 7, 0.5), (2, 5, 1), (3, 4, 1)],
        [(0, 4, 1), (1, 7, 1), (2, 12, 1), (3, 16, 1)],
        [(0, 14, 1.5), (1.5, 12, 0.5), (2, 11, 1), (3, 14, 1)],
        [(0, 12, 1), (1, 9, 1), (2, 5, 1), (3, 9, 1)],
        [(0, 7, 2), (2, 11, 1), (3, 14, 1)],
    ]
    # The second half rests for two bars, then answers.
    answer = [[], []] + tune[2:]

    for k, (root, tones) in enumerate(bars):
        t0 = k * bar
        # Pad: the chord, softly, an octave down.
        for s in tones:
            add(pad_voice(note(s - 12), bar + 1.2), (t0 - 0.6) % (n / rate), 0.07)
        # Bass: root on beats 1 and 3, a fifth on the "and" of 4.
        add(pluck(root - 24, 1.0, SOFT, 0.25), t0, 0.32)
        add(pluck(root - 24, 0.8, SOFT, 0.2), t0 + 2 * beat, 0.26)
        add(pluck(root - 17, 0.5, SOFT, 0.12), t0 + 3.5 * beat, 0.18)
        # Arpeggio: bouncing eighth notes through the chord.
        pattern = [tones[0], tones[1], tones[2], tones[1] + 12, tones[2], tones[1], tones[0] + 12, tones[2]]
        for e, s in enumerate(pattern):
            add(pluck(s - 12, 0.5, MARIMBA, 0.12), t0 + e * beat / 2, 0.13 if e % 2 == 0 else 0.09)
        # Melody.
        for b, s, d in (tune if k < 8 else answer)[k % 8]:
            add(pluck(s, max(0.6, d * beat + 0.4), BELL, 0.22 + 0.1 * d), t0 + b * beat, 0.2)

    # Wrap the overflow into the start so the loop is seamless.
    for i in range(tail):
        out[i] += out[n + i]
    track = out[:n]
    track = lowpass(track + track[: int(2.0 * rate)], 5000, rate)
    track = reverb(track, wet=0.45, size=1.6, tail=0, rate=rate)
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
