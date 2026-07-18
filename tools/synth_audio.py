#!/usr/bin/env python3
"""Synthesized, license-free audio for every slot in assets/audio/MANIFEST.md.

These are proper sound-design placeholders (not beeps): layered noise, drones,
and envelope work. Replace any file with a sourced recording of the same name
and it plays instead — no code changes. Ambient/music files are loop-cleaned
with an end-to-start crossfade.
"""
import os
import wave
import numpy as np

SR = 44100
ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(7)


# ---------- primitives ----------

def t(dur):
    return np.arange(int(SR * dur)) / SR

def white(dur):
    return rng.standard_normal(int(SR * dur))

def brown(dur):
    x = np.cumsum(white(dur))
    return x / (np.abs(x).max() + 1e-9)

def onepole_lp(x, cutoff):
    a = np.exp(-2.0 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    b = 1.0 - a
    for i in range(len(x)):
        acc = a * acc + b * x[i]
        y[i] = acc
    return y

def lp(x, cutoff):
    # two cascaded one-poles, vectorized via lfilter-style recursion in numpy
    from numpy import zeros_like
    a = float(np.exp(-2.0 * np.pi * cutoff / SR))
    b = 1.0 - a
    y = np.copy(x)
    for _ in range(2):
        z = np.empty_like(y)
        acc = 0.0
        for i in range(len(y)):
            acc = a * acc + b * y[i]
            z[i] = acc
        y = z
    return y

def hp(x, cutoff):
    return x - lp(x, cutoff)

def bp(x, lo, hi):
    return hp(lp(x, hi), lo)

def env_exp(dur, tau):
    return np.exp(-t(dur) / tau)

def slow_lfo(dur, hz, depth, base=1.0):
    return base + depth * np.sin(2 * np.pi * hz * t(dur) + rng.uniform(0, 6.28))

def wobble(dur, hz, depth):
    """Smoothed random amplitude drift around 1.0."""
    n = int(SR * dur)
    pts = rng.standard_normal(int(dur * hz) + 2)
    x = np.interp(np.linspace(0, len(pts) - 1, n), np.arange(len(pts)), pts)
    return 1.0 + depth * x

def loopify(x, fade=0.5):
    n = int(SR * fade)
    if x.ndim == 1:
        head, tail = x[:n], x[-n:]
        w = np.linspace(0, 1, n)
        x[:n] = head * w + tail * (1 - w)
        return x[:-n]
    for c in range(x.shape[0]):
        x[c] = np.concatenate([x[c][:0], x[c]])
    head = x[:, :n] * np.linspace(0, 1, n) + x[:, -n:] * np.linspace(1, 0, n)
    x[:, :n] = head
    return x[:, :-n]

def norm(x, peak_db=-12.0):
    p = np.abs(x).max() + 1e-9
    return x * (10 ** (peak_db / 20.0) / p)

def write_wav(rel, x, peak_db=-12.0):
    x = norm(np.asarray(x, dtype=np.float64), peak_db)
    if x.ndim == 1:
        x = np.stack([x, x]) if rel.startswith(("ambient", "music")) else x[None, :]
    pcm = (np.clip(x.T, -1, 1) * 32767).astype(np.int16)
    path = os.path.join(ROOT, rel + ".wav")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(pcm.shape[1] if pcm.ndim > 1 else 1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    dur = pcm.shape[0] / SR
    rms = 20 * np.log10(np.sqrt((x ** 2).mean()) + 1e-9)
    print(f"{rel:28s} {dur:6.1f}s  peak {peak_db:+.0f} dB  rms {rms:+.1f} dB")


def stereo(mono_fn, dur, spread=1.0):
    """Two decorrelated renders for width."""
    return np.stack([mono_fn(dur), mono_fn(dur) * spread])


# ---------- ambient loops ----------

def engine_drone(dur):
    """Four detuned radial engines: low harmonics that beat against each
    other (the classic multi-engine throb) + airframe noise rush."""
    x = np.zeros(int(SR * dur))
    for f0 in (54.0, 55.3, 57.1, 58.6):
        for h, g in ((1, 1.0), (2, 0.55), (3, 0.3), (4, 0.18), (6, 0.08)):
            ph = rng.uniform(0, 6.28)
            x += g * np.sin(2 * np.pi * f0 * h * t(dur) + ph)
    x *= wobble(dur, 0.4, 0.18)
    rush = lp(white(dur), 900) * 0.5 * wobble(dur, 0.7, 0.25)
    rattle = bp(white(dur), 1200, 2400) * 0.06 * (wobble(dur, 6, 0.5) > 1.25)
    return x * 0.14 + rush + rattle

def wind(dur, gustiness=0.5, base_cut=700):
    g = np.clip(wobble(dur, 0.25, gustiness), 0.25, 2.2)
    body = lp(white(dur), base_cut) * g
    whistle = bp(white(dur), 700, 1400) * 0.18 * np.clip(g - 0.9, 0, 2)
    return body + whistle

def burst(ln, tau):
    """Exact-length noise burst with exponential decay."""
    return rng.standard_normal(ln) * np.exp(-(np.arange(ln) / SR) / tau)

def fire_crackle(dur):
    n = int(SR * dur)
    x = np.zeros(n)
    n_pops = int(dur * 14)
    for _ in range(n_pops):
        i = int(rng.integers(0, n - 4000))
        ln = int(rng.integers(300, 3000))
        x[i:i + ln] += burst(ln, rng.uniform(0.004, 0.02)) * rng.uniform(0.2, 1.0)
    x = lp(x, 3200)
    bed = lp(brown(dur), 240) * 0.9 * wobble(dur, 0.5, 0.15)
    return x * 0.5 + bed

def night_interior(dur):
    room = lp(brown(dur), 130) * 0.7
    fire = fire_crackle(dur) * 0.8
    return room + fire

def hardstand_dawn(dur):
    base = wind(dur, gustiness=0.35, base_cut=500) * 0.8
    # very distant idling engine
    idle = np.sin(2 * np.pi * 41 * t(dur)) * 0.05 * wobble(dur, 0.3, 0.3)
    # sparse, distant birds: quiet down-chirps
    n = int(SR * dur)
    birds = np.zeros(n)
    for _ in range(int(dur / 6)):
        i = int(rng.integers(0, n - SR))
        ln = int(rng.integers(2500, 6000))
        tt = np.arange(ln) / SR
        f = rng.uniform(2400, 3400) * (1 - 0.4 * tt / (ln / SR))
        decay = np.exp(-tt / 0.03)
        birds[i:i + ln] += np.sin(2 * np.pi * f * tt) * decay * 0.05
    return base + idle + lp(birds, 4000)


# ---------- sfx ----------

def m2_shot():
    dur = 0.28
    burst = white(dur) * env_exp(dur, 0.03)
    body = np.sin(2 * np.pi * 150 * t(dur) * (1 - 0.5 * t(dur))) * env_exp(dur, 0.05) * 0.8
    x = lp(burst, 3500) + body
    return hp(x, 60)

def flak_close():
    dur = 1.7
    thump = np.sin(2 * np.pi * (58 * (1 - 0.4 * np.clip(t(dur) / 0.3, 0, 1))) * t(dur)) \
        * env_exp(dur, 0.16) * 1.2
    burst = lp(white(dur), 750) * env_exp(dur, 0.05)
    rumble = lp(brown(dur), 160) * env_exp(dur, 0.5) * 1.4
    rattle = bp(white(dur), 900, 2000) * env_exp(dur, 0.3) * (0.5 + 0.5 * np.sin(2 * np.pi * 27 * t(dur))) * 0.35
    return thump + burst + rumble + rattle

def chute_open():
    dur = 0.8
    n = int(SR * dur)
    woosh = white(dur)
    # rising sweep then hard snap
    sweep = bp(woosh, 250, 900) * np.linspace(0.2, 1.0, n) ** 2
    snap_at = int(0.42 * SR)
    snap = np.zeros(n)
    ln = int(0.09 * SR)
    snap[snap_at:snap_at + ln] = burst(ln, 0.008) * 2.2
    thud = np.zeros(n)
    tt = t(dur) - 0.42
    m = tt > 0
    thud[m] = np.sin(2 * np.pi * 130 * tt[m]) * np.exp(-tt[m] / 0.07) * 0.9
    return lp(sweep, 2500) + lp(snap, 4000) + thud

def distant_gunfire():
    dur = 2.6
    n = int(SR * dur)
    x = np.zeros(n)
    pos = 0.1
    while pos < dur - 0.2:
        i = int(pos * SR)
        ln = int(0.05 * SR)
        x[i:i + ln] += burst(ln, 0.012) * rng.uniform(0.5, 1.0)
        pos += rng.uniform(0.08, 0.3)
    return lp(x, 520)

def impact_thud():
    dur = 0.65
    body = np.sin(2 * np.pi * (52 * (1 - 0.5 * np.clip(t(dur) / 0.2, 0, 1))) * t(dur)) * env_exp(dur, 0.09) * 1.3
    scuff = bp(white(dur), 300, 1400) * env_exp(dur, 0.04) * 0.5
    return body + scuff


def morning_farm(dur):
    """Cold, quiet farm morning: light wind, sparse close birds, one far dog."""
    base = wind(dur, gustiness=0.25, base_cut=420) * 0.6
    n = int(SR * dur)
    birds = np.zeros(n)
    for _ in range(int(dur / 2.5)):
        i = int(rng.integers(0, n - SR))
        for k in range(int(rng.integers(2, 5))):   # short chirp phrases
            j = i + int(k * rng.uniform(0.09, 0.16) * SR)
            ln = int(rng.integers(1800, 4200))
            if j + ln >= n:
                break
            tt = np.arange(ln) / SR
            f = rng.uniform(2600, 4200) * (1 + 0.25 * np.sin(2 * np.pi * 30 * tt))
            birds[j:j + ln] += np.sin(2 * np.pi * f * tt) * np.exp(-tt / 0.05) * 0.07
    dog = np.zeros(n)
    for _ in range(max(1, int(dur / 14))):
        i = int(rng.integers(int(n * 0.2), n - SR))
        ln = int(0.16 * SR)
        tt = np.arange(ln) / SR
        dog[i:i + ln] += np.sin(2 * np.pi * (300 - 120 * tt / 0.16) * tt) * np.exp(-tt / 0.06) * 0.05
    return base + lp(birds, 5000) + lp(dog, 700)

def knock_door():
    """Three knuckle strikes on heavy wood, unhurried, official."""
    dur = 1.5
    n = int(SR * dur)
    x = np.zeros(n)
    for at in (0.1, 0.42, 0.74):
        i = int(at * SR)
        ln = int(0.11 * SR)
        tt = np.arange(ln) / SR
        thud = np.sin(2 * np.pi * (95 - 30 * tt / 0.11) * tt) * np.exp(-tt / 0.03) * 1.2
        rap = burst(ln, 0.004) * 0.8
        x[i:i + ln] += thud + lp(rap, 2200)
    return x

def truck_pass(dur=11.0):
    """A heavy engine approaching, passing, receding — level and pitch ride
    a triangle centered on the pass."""
    n = int(SR * dur)
    tt = t(dur)
    prox = 1.0 - np.abs(tt - dur * 0.45) / (dur * 0.55)   # 0..1..0
    prox = np.clip(prox, 0.0, 1.0) ** 1.6
    f0 = 68 * (1.0 + 0.06 * (tt < dur * 0.45) - 0.05 * (tt >= dur * 0.45))  # crude doppler step
    eng = np.sin(2 * np.pi * np.cumsum(f0) / SR)
    eng += 0.55 * np.sin(2 * np.pi * np.cumsum(f0 * 2.02) / SR)
    eng += 0.3 * np.sin(2 * np.pi * np.cumsum(f0 * 2.98) / SR)
    eng *= 0.5 + 0.5 * wobble(dur, 9.0, 0.25)
    tires = lp(white(dur), 380) * 0.5
    x = (lp(eng, 500) + tires) * (0.08 + 0.92 * prox)
    return x

def rifle_crack():
    """One rifle shot, outdoors: hard crack, then a flat rolling echo."""
    dur = 2.4
    n = int(SR * dur)
    x = np.zeros(n)
    ln = int(0.10 * SR)
    x[:ln] += burst(ln, 0.006) * 2.4
    body = np.sin(2 * np.pi * 170 * t(dur) * (1 - 0.4 * np.clip(t(dur) / 0.1, 0, 1))) * env_exp(dur, 0.05) * 0.7
    x += body
    # echo tail: delayed, darker copies
    for d, g in ((0.28, 0.30), (0.55, 0.18), (0.9, 0.10)):
        i = int(d * SR)
        x[i:i + ln] += lp(burst(ln, 0.02), 900) * g
    roll = lp(brown(dur), 220) * env_exp(dur, 0.6) * 0.5
    return hp(x + roll, 55)


def fighter_guns():
    """An Fw 190's cannon burst from off your beam: faster, harder, more
    metallic than the distant rifle volley."""
    dur = 1.1
    n = int(SR * dur)
    x = np.zeros(n)
    pos = 0.02
    while pos < dur - 0.15:
        i = int(pos * SR)
        ln = int(0.045 * SR)
        x[i:i + ln] += burst(ln, 0.008) * rng.uniform(0.8, 1.1)
        pos += 0.075   # ~13 rounds/sec
    body = bp(x, 500, 2600)
    thump = lp(x, 300) * 1.6
    return body + thump

def engine_dying(dur=9.0):
    """A stricken bomber's engines falling away: detuned drone sliding down
    in pitch and level, with a rough flutter growing as it goes."""
    n = int(SR * dur)
    tt = t(dur)
    slide = np.linspace(1.0, 0.62, n) ** 1.2
    f0 = 62 * slide
    x = np.sin(2 * np.pi * np.cumsum(f0) / SR)
    x += 0.6 * np.sin(2 * np.pi * np.cumsum(f0 * 1.98) / SR)
    x += 0.35 * np.sin(2 * np.pi * np.cumsum(f0 * 3.03) / SR)
    flutter = 1.0 - 0.45 * np.clip(tt / dur, 0, 1) * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 11 * tt)))
    x *= flutter
    x = lp(x, 700)
    fade = np.linspace(1.0, 0.15, n)
    return x * fade * 0.8

def alarm_bell():
    """The bail-out bell: three hard rings of a small steel bell."""
    dur = 2.6
    n = int(SR * dur)
    x = np.zeros(n)
    for at in (0.05, 0.85, 1.65):
        i = int(at * SR)
        ln = int(0.75 * SR)
        tt = np.arange(ln) / SR
        ring = np.zeros(ln)
        for f, g in ((1180, 1.0), (1760, 0.55), (2420, 0.3), (760, 0.4)):
            ring += np.sin(2 * np.pi * f * tt) * g
        ring *= np.exp(-tt / 0.22)
        strike = burst(int(0.01 * SR), 0.002) * 1.5
        ring[:len(strike)] += strike
        x[i:i + ln] += ring
    return hp(x, 300) * 0.7


def town_day(dur):
    """Small-town daytime from an upstairs room: muffled street, a cart on
    cobbles now and then, one church bell strike."""
    base = lp(brown(dur), 240) * 0.55
    n = int(SR * dur)
    cart = np.zeros(n)
    for _ in range(int(dur / 9)):
        i = int(rng.integers(0, n - 3 * SR))
        for k in range(int(rng.integers(6, 12))):
            j = i + int(k * rng.uniform(0.16, 0.24) * SR)
            ln = int(0.05 * SR)
            if j + ln >= n:
                break
            cart[j:j + ln] += burst(ln, 0.01) * 0.12
    bell = np.zeros(n)
    i = int(n * 0.55)
    ln = int(2.2 * SR)
    tt = np.arange(ln) / SR
    for f, g in ((392, 1.0), (587, 0.4), (784, 0.25)):
        bell[i:i + ln] += np.sin(2 * np.pi * f * tt) * g
    bell[i:i + ln] *= np.exp(-tt / 0.8) * 0.10
    return base + lp(cart, 600) + lp(bell, 2000)

def station_dusk(dur):
    """Station forecourt: low crowd murmur, periodic steam hiss, one far
    whistle."""
    murmur = lp(brown(dur), 300) * 0.6 + bp(white(dur), 150, 500) * 0.10
    n = int(SR * dur)
    steam = np.zeros(n)
    for _ in range(int(dur / 8)):
        i = int(rng.integers(0, n - 4 * SR))
        ln = int(rng.uniform(1.8, 3.2) * SR)
        tt = np.arange(ln) / SR
        env = np.minimum(tt / 0.4, 1.0) * np.exp(-tt / 1.4)
        steam[i:i + ln] += bp(rng.standard_normal(ln), 900, 2600) * env * 0.16
    whistle = np.zeros(n)
    i = int(n * 0.7)
    ln = int(1.4 * SR)
    tt = np.arange(ln) / SR
    whistle[i:i + ln] = (np.sin(2 * np.pi * 620 * tt) + 0.5 * np.sin(2 * np.pi * 930 * tt)) \
        * np.exp(-tt / 0.9) * 0.05
    return murmur + steam + lp(whistle, 3000)

def radio_static(dur=22.0):
    """BBC under a blanket: band-limited static, a drifting heterodyne
    whine, and the Greenwich time pips."""
    n = int(SR * dur)
    static = bp(white(dur), 300, 3000) * 0.5
    drift = 800 + 300 * np.sin(2 * np.pi * t(dur) / 7.0)
    whine = np.sin(2 * np.pi * np.cumsum(drift) / SR) * 0.05 * wobble(dur, 0.4, 0.5)
    pips = np.zeros(n)
    for k in range(6):
        i = int((2.0 + k) * SR)
        ln = int((0.1 if k < 5 else 0.5) * SR)
        if i + ln < n:
            pips[i:i + ln] = np.sin(2 * np.pi * 1000 * np.arange(ln) / SR) * 0.12
    voice = lp(brown(dur), 400) * 0.25 * (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * t(dur) / 3.7)))
    return static + whine + pips + voice

def chapter_sting(dur=9.0):
    """End-of-chapter sting: one dark swell on the title theme's A-minor
    root, surfacing and sinking. Non-looping."""
    n = int(SR * dur)
    x = np.zeros(n)
    for f, g in ((55.0, 0.5), (82.4, 0.3), (110.0, 0.18), (164.8, 0.08)):
        ph = rng.uniform(0, 6.28)
        for d in (-0.3, 0.0, 0.3):
            x += np.sin(2 * np.pi * (f + d) * t(dur) + ph) * g / 3
    x = lp(x, 420)
    swell = np.sin(np.pi * np.clip(t(dur) / dur, 0, 1)) ** 1.6
    hi = np.sin(2 * np.pi * 659.3 * t(dur)) * 0.03 * np.clip(swell - 0.5, 0, 1) * 2
    return (x * swell) + hi

def stamp_thunk():
    """A rubber stamp brought down hard on papers over wood, twice."""
    dur = 1.1
    n = int(SR * dur)
    x = np.zeros(n)
    for at in (0.08, 0.55):
        i = int(at * SR)
        ln = int(0.12 * SR)
        tt = np.arange(ln) / SR
        thud = np.sin(2 * np.pi * (120 - 40 * tt / 0.12) * tt) * np.exp(-tt / 0.025) * 1.3
        slap = burst(ln, 0.003) * 0.9
        x[i:i + ln] += thud + lp(slap, 3200)
    return x


def city_night(dur):
    """Blackout Paris after curfew: wind channelled down a stone canyon,
    one far car, one cat, shutters ticking."""
    base = wind(dur, gustiness=0.45, base_cut=350) * 0.55
    n = int(SR * dur)
    far_car = np.zeros(n)
    i = int(n * 0.35)
    ln = int(6.0 * SR)
    tt = np.arange(ln) / SR
    prox = np.sin(np.pi * tt / 6.0) ** 2
    eng = np.sin(2 * np.pi * 55 * tt) + 0.4 * np.sin(2 * np.pi * 111 * tt)
    far_car[i:i + ln] += eng * prox * 0.04
    cat = np.zeros(n)
    i = int(n * 0.72)
    ln = int(0.7 * SR)
    tt = np.arange(ln) / SR
    cat[i:i + ln] = np.sin(2 * np.pi * (620 + 180 * np.sin(np.pi * tt / 0.7)) * tt) \
        * np.sin(np.pi * tt / 0.7) * 0.03
    ticks = np.zeros(n)
    for _ in range(int(dur / 5)):
        j = int(rng.integers(0, n - 2000))
        ticks[j:j + 900] += burst(900, 0.004) * 0.05
    return base + lp(far_car, 300) + lp(cat, 2000) + lp(ticks, 1800)

def apartment_day(dur):
    """A fifth floor with the city far below: muffled street murmur, pipes
    knocking, a clock, a chair scrape somewhere under the floor."""
    murmur = lp(brown(dur), 200) * 0.5
    n = int(SR * dur)
    clock = np.zeros(n)
    for k in range(int(dur)):
        i = int(k * SR)
        if i + 1500 < n:
            clock[i:i + 1500] += burst(1500, 0.003) * (0.05 if k % 2 == 0 else 0.038)
    pipes = np.zeros(n)
    for _ in range(int(dur / 11)):
        i = int(rng.integers(0, n - SR))
        for k in range(int(rng.integers(2, 5))):
            j = i + int(k * 0.3 * SR)
            if j + 3000 < n:
                pipes[j:j + 3000] += np.sin(2 * np.pi * 210 * np.arange(3000) / SR) \
                    * np.exp(-np.arange(3000) / SR / 0.05) * 0.06
    return murmur + lp(clock, 3500) + lp(pipes, 900)

def boots_stairs(dur=10.0):
    """Boots on a wooden stair, several pairs, rising floor by floor —
    unhurried and getting nearer the whole time."""
    n = int(SR * dur)
    x = np.zeros(n)
    step_t = 0.2
    pos = 0.0
    k = 0
    while pos < dur - 0.3:
        i = int(pos * SR)
        near = k / (dur / step_t)   # 0 → 1: they climb toward you
        ln = int(0.09 * SR)
        thud = np.sin(2 * np.pi * (70 + 25 * near) * np.arange(ln) / SR) \
            * np.exp(-np.arange(ln) / SR / 0.02) * (0.25 + 0.75 * near)
        crk = burst(ln, 0.006) * 0.3 * (0.3 + 0.7 * near)
        x[i:i + ln] += thud + lp(crk, 1400 + 1200 * near)
        pos += step_t * rng.uniform(0.92, 1.08)
        k += 1
    return lp(x, 2600)

def car_trap(dur=8.0):
    """A big engine arriving and idling; two doors, unhurried."""
    n = int(SR * dur)
    tt = t(dur)
    approach = np.clip(tt / 2.5, 0, 1)
    f0 = 48 * (1.0 + 0.05 * np.sin(2 * np.pi * 0.8 * tt))
    eng = np.sin(2 * np.pi * np.cumsum(f0) / SR) + 0.5 * np.sin(2 * np.pi * np.cumsum(f0 * 2.01) / SR)
    eng *= (0.12 + 0.55 * approach) * (1.0 - 0.35 * np.clip((tt - 5.5) / 2.0, 0, 1))
    x = lp(eng, 350)
    for at in (5.6, 6.4):
        i = int(at * SR)
        ln = int(0.12 * SR)
        thunk = np.sin(2 * np.pi * 130 * np.arange(ln) / SR) * np.exp(-np.arange(ln) / SR / 0.02) * 0.9
        x[i:i + ln] += thunk + lp(burst(ln, 0.004), 2400) * 0.5
    return x

def cell_door(dur=2.8):
    """Iron on stone: a bolt, a swing with a low groan, the slam's echo."""
    n = int(SR * dur)
    x = np.zeros(n)
    ln = int(0.1 * SR)
    x[:ln] += bp(burst(ln, 0.008), 1200, 4200) * 1.2   # the bolt
    gi = int(0.5 * SR)
    gl = int(1.0 * SR)
    tt = np.arange(gl) / SR
    x[gi:gi + gl] += np.sin(2 * np.pi * (90 - 25 * tt) * tt) * np.exp(-tt / 0.8) * 0.35  # the groan
    si = int(1.7 * SR)
    sl = int(0.5 * SR)
    tt = np.arange(sl) / SR
    x[si:si + sl] += (np.sin(2 * np.pi * 60 * tt) * np.exp(-tt / 0.06) * 1.4
        + lp(burst(sl, 0.01), 900) * 0.8)   # the slam + rolling echo
    return x


# ---------- music ----------

def title_theme(dur):
    """Dark, slow drone in A minor: detuned low saws swelling under a faint
    high sine that surfaces twice. Somber, restrained."""
    n = int(SR * dur)
    x = np.zeros(n)

    def soft_saw(f, detune, gain):
        s = np.zeros(n)
        for d in (-detune, 0.0, detune):
            ph = rng.uniform(0, 6.28)
            for h in range(1, 7):
                s += ((-1) ** h / h) * np.sin(2 * np.pi * (f + d) * h * t(dur) + ph * h)
        return s * gain

    x += soft_saw(55.0, 0.35, 0.30)    # A1
    x += soft_saw(82.4, 0.30, 0.22)    # E2
    x += soft_saw(130.8, 0.25, 0.10)   # C3
    x = lp(x, 480)
    x *= 0.6 + 0.4 * np.sin(2 * np.pi * t(dur) / (dur / 2) - np.pi / 2)  # two slow swells
    # faint high E surfacing in each swell
    hi = np.sin(2 * np.pi * 659.3 * t(dur))
    gate = np.clip(np.sin(2 * np.pi * t(dur) / (dur / 2) - np.pi / 2), 0, 1) ** 3
    x += hi * gate * 0.035
    breath = lp(white(dur), 300) * 0.05
    return x + breath


if __name__ == "__main__":
    print("synthesizing to", os.path.abspath(ROOT))
    write_wav("ambient/bomber_interior", loopify(np.stack([engine_drone(26), engine_drone(26)])), -14)
    write_wav("ambient/wind_descent", loopify(np.stack([wind(24), wind(24)])), -16)
    write_wav("ambient/night_interior", loopify(np.stack([night_interior(32), night_interior(32)])), -20)
    write_wav("ambient/hardstand_dawn", loopify(np.stack([hardstand_dawn(28), hardstand_dawn(28)])), -19)
    write_wav("sfx/m2_shot", m2_shot(), -10)
    write_wav("sfx/flak_close", flak_close(), -10)
    write_wav("sfx/chute_open", chute_open(), -11)
    write_wav("sfx/distant_gunfire", distant_gunfire(), -16)
    write_wav("sfx/impact_thud", impact_thud(), -10)
    write_wav("ambient/morning_farm", loopify(np.stack([morning_farm(30), morning_farm(30)])), -20)
    write_wav("sfx/knock_door", knock_door(), -12)
    write_wav("sfx/truck_pass", truck_pass(), -13)
    write_wav("sfx/rifle_crack", rifle_crack(), -10)
    write_wav("sfx/fighter_guns", fighter_guns(), -13)
    write_wav("sfx/engine_dying", engine_dying(), -16)
    write_wav("sfx/alarm_bell", alarm_bell(), -12)
    write_wav("ambient/town_day", loopify(np.stack([town_day(30), town_day(30)])), -21)
    write_wav("ambient/station_dusk", loopify(np.stack([station_dusk(30), station_dusk(30)])), -19)
    write_wav("sfx/radio_static", radio_static(), -16)
    write_wav("sfx/stamp_thunk", stamp_thunk(), -11)
    write_wav("sfx/chapter_sting", chapter_sting(), -15)
    write_wav("ambient/city_night", loopify(np.stack([city_night(28), city_night(28)])), -20)
    write_wav("ambient/apartment_day", loopify(np.stack([apartment_day(30), apartment_day(30)])), -22)
    write_wav("sfx/boots_stairs", boots_stairs(), -14)
    write_wav("sfx/car_trap", car_trap(), -12)
    write_wav("sfx/cell_door", cell_door(), -11)
    write_wav("music/title_theme", loopify(np.stack([title_theme(52), title_theme(52)]), 1.0), -16)
    print("done")
