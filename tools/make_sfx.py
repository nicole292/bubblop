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


def effects():
    os.makedirs(OUT, exist_ok=True)

    # Pops: a round marimba note that "bloops" up into pitch, with a quiet
    # bell an octave above for sparkle.
    pentatonic = [0, 2, 4, 7, 9, 12, 14, 16]
    for step, semis in enumerate(pentatonic):
        f = note(semis - 5)
        body = tone(f, 0.45, attack=0.004, decay=0.11, partials=MARIMBA, bend=-3, bend_time=0.012)
        shine = gain(tone(f * 2, 0.35, attack=0.008, decay=0.08, partials=BELL), 0.16)
        save(f"pop_{step}", lowpass(mix(body, shine, offsets=[0, 0.01]), 5000), peak=0.62)

    # Landing: a soft, low wooden "tok".
    save("land", tone(196, 0.16, attack=0.003, decay=0.035, partials=((1, 1.0, 1.0), (2.6, 0.12, 0.3)),
                      bend=4, bend_time=0.01), peak=0.38, room=0.1)

    # Shell bubble breaking: a glassy chime and a little bubble.
    chime = mix(tone(note(19), 0.6, decay=0.16, partials=BELL),
                gain(tone(note(26), 0.5, decay=0.12, partials=BELL), 0.5), offsets=[0, 0.03])
    bubble = gain(tone(note(7), 0.12, attack=0.003, decay=0.03, bend=-7, bend_time=0.015), 0.6)
    save("crack", lowpass(mix(bubble, chime, offsets=[0, 0.012]), 6000), peak=0.5)

    # A row rising: a gentle upward swell of two soft notes.
    swell = mix(tone(note(-17), 0.5, attack=0.12, decay=0.18, partials=SOFT, bend=-5, bend_time=0.15),
                gain(tone(note(-10), 0.5, attack=0.14, decay=0.18, partials=SOFT, bend=-5, bend_time=0.15), 0.6))
    save("rise", swell, peak=0.42)

    # Rejected drop (full column): two soft, low, falling notes -- a polite "nope".
    nope = mix(tone(note(-8), 0.18, decay=0.05, partials=MARIMBA),
               tone(note(-12), 0.25, decay=0.07, partials=MARIMBA), offsets=[0, 0.09])
    save("deny", lowpass(nope, 2500), peak=0.32, room=0.12)

    # UI tap: a tiny, soft woodblock.
    save("tap", lowpass(tone(note(7), 0.1, attack=0.002, decay=0.02, partials=MARIMBA), 4000), peak=0.32, room=0.08)

    # Praise sparkle: a quick rising run of little bells.
    run = [gain(tone(note(s), 0.5, decay=0.12, partials=BELL), 0.8 + 0.05 * k) for k, s in enumerate((12, 16, 19, 24))]
    save("praise", lowpass(mix(*run, offsets=[0, 0.055, 0.11, 0.165]), 6000), peak=0.48, room=0.3)

    # Level up: a warm arpeggio with a soft chord underneath.
    arp = [tone(note(s), 0.7, decay=0.18, partials=BELL) for s in (0, 4, 7, 12)]
    pad = gain(mix(*[tone(note(s), 0.9, attack=0.08, decay=0.3, partials=SOFT) for s in (-12, -5, 4)]), 0.25)
    save("levelup", lowpass(mix(pad, *arp, offsets=[0, 0, 0.08, 0.16, 0.24]), 6000), peak=0.52, room=0.3)

    # New best: a longer, happier run that lands on a bright chord.
    run = [tone(note(s), 0.6, decay=0.16, partials=BELL) for s in (0, 4, 7, 12, 16, 19)]
    final = mix(*[gain(tone(note(s), 1.4, attack=0.01, decay=0.4, partials=BELL), 0.6) for s in (12, 16, 19, 24)])
    pad = gain(mix(*[tone(note(s), 1.6, attack=0.1, decay=0.5, partials=SOFT) for s in (-12, -5, 4)]), 0.25)
    save("newbest", lowpass(mix(*run, final, pad, offsets=[0, 0.07, 0.14, 0.21, 0.28, 0.35, 0.44, 0.3]), 6000),
         peak=0.55, room=0.35)

    # Game over: gentle and descending (not punishing), settling on a soft chord.
    down = [tone(note(s), 0.8, decay=0.22, partials=SOFT) for s in (7, 4, 2, 0)]
    rest = gain(mix(*[tone(note(s), 1.6, attack=0.06, decay=0.5, partials=SOFT) for s in (-12, -5, 0, 4)]), 0.35)
    save("gameover", lowpass(mix(*down, rest, offsets=[0, 0.16, 0.32, 0.48, 0.48]), 3500), peak=0.45, room=0.35)


def music():
    """A slow, quiet, seamlessly looping piece: a soft pad drifting through
    four chords, a low root, and a few sparse music-box notes on top."""
    os.makedirs(MUSIC_OUT, exist_ok=True)
    rate = MUSIC_RATE
    rnd = random.Random(7)
    chord_len = 8.0
    # Cmaj9, Am7, Fmaj7, Gsus/add9 -- semitones from C5, voiced low.
    chords = [(-24, -12, -5, -1, 2), (-27, -15, -8, -5, -1), (-31, -19, -8, -5, 0), (-29, -17, -10, -5, 2)]
    progression = chords * 2
    length = chord_len * len(progression)
    n = int(length * rate)
    tail = int(6 * rate)
    out = [0.0] * (n + tail)

    def add(track, start_s, g):
        start = int(start_s * rate)
        for i, s in enumerate(track):
            j = start + i
            out[j % n if j >= n + tail else j] += s * g

    def pad_voice(freq, dur):
        """A slow-breathing sine with a faint octave and a slight detune chorus."""
        m = int(dur * rate)
        res = [0.0] * m
        p1 = p2 = p3 = 0.0
        for i in range(m):
            t = i / rate
            e = math.sin(math.pi * t / dur) ** 2
            p1 += TAU * freq / rate
            p2 += TAU * freq * 1.003 / rate
            p3 += TAU * freq * 2 / rate
            res[i] = e * (math.sin(p1) + 0.6 * math.sin(p2) + 0.12 * math.sin(p3))
        return res

    pentatonic = [0, 2, 4, 7, 9, 12, 14]
    for k, chord in enumerate(progression):
        start = k * chord_len - 2.0  # chords overlap and crossfade
        dur = chord_len + 4.0
        for semis in chord[1:]:
            add(pad_voice(note(semis), dur), start % length, 0.11)
        add(pad_voice(note(chord[0]), dur), start % length, 0.16)
        # Two or three sparse music-box notes per chord, picked from the chord.
        times = sorted(rnd.sample([0.5, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5], rnd.choice((2, 3))))
        for t in times:
            semis = rnd.choice([s for s in pentatonic if (s - chord[2]) % 12 in {(c - chord[2]) % 12 for c in chord} or s in (7, 14)])
            bell = tone(note(semis), 2.5, attack=0.01, decay=0.6, partials=BELL, rate=rate)
            add(bell, k * chord_len + t, 0.07)

    # Wrap the overflow into the start so the loop is seamless.
    for i in range(tail):
        out[i] += out[n + i]
    track = out[:n]
    track = lowpass(track + track[: int(2.0 * rate)], 3200, rate)
    track = reverb(track, wet=0.6, size=2.2, tail=0, rate=rate)
    # The reverbed copy of the first 2 s is folded back so the loop stays seamless.
    head = track[n:]
    track = track[:n]
    for i, s in enumerate(head):
        w = i / len(head)
        track[i] = track[i] * w + s * (1 - w)
    m = max(abs(s) for s in track)
    write_wav(os.path.join(MUSIC_OUT, "calm.wav"), [s * 0.7 / m for s in track], rate)


if __name__ == "__main__":
    effects()
    music()
