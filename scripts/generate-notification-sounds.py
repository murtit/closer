#!/usr/bin/env python3
"""Generates Closer's own notification sounds as WAV files.

Usage:
  scripts/generate-notification-sounds.py           # writes Closer/Resources/Sounds/*.wav
  scripts/generate-notification-sounds.py --check   # exits with 1 if the committed files are out of date

Apps may not use the iPhone's ringtones or alert tones for their notifications; besides the
system default, iOS only plays sounds that ship in the app bundle (`UNNotificationSound(named:)`,
linear PCM / IMA4 / µLaw / aLaw in .aiff, .wav or .caf, at most 30 seconds). Closer's sounds are
therefore synthesised here from a few notes, so they are its own and can be changed and
regenerated like the app icon.

All sounds share one character: soft, bell-like tones with a quick attack and a warm, short
tail, in the higher register that iPhone speakers play well. The file names must match
`NotificationSound.fileName` in the app.

Output: 44.1 kHz, 16 bit, mono, linear PCM. Rendering only uses the standard library; `--check`
allows a difference of a few LSB per sample, so the slightly different floating point math of
macOS and Linux does not fail the check.
"""
import math
import os
import struct
import sys
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOUNDS = os.path.join(ROOT, "Closer", "Resources", "Sounds")

RATE = 44100
PEAK = 0.84           # about -1.5 dBFS
TOLERANCE = 4         # LSB per sample in --check
MAX_SECONDS = 30      # iOS limit for notification sounds


def hz(note: str) -> float:
    """"A5" → 880.0, "C#6" → 1108.73."""
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    semitone = names[note[0]] + (1 if "#" in note else 0)
    octave = int(note[-1])
    return 440.0 * 2 ** ((semitone + 12 * (octave - 4)) / 12)


# Partials (frequency ratio, amplitude, decay factor) of the two voices. Slightly inharmonic
# upper partials make the bell; they also fade faster than the fundamental.
BELL = [(1.0, 1.0, 1.0), (2.0, 0.32, 1.8), (3.01, 0.12, 2.6), (4.18, 0.05, 3.4)]
PLUCK = [(1.0, 1.0, 1.0), (2.0, 0.45, 2.2), (3.0, 0.18, 3.5)]


class Track:
    def __init__(self, seconds: float):
        self.samples = [0.0] * int(seconds * RATE)

    def note(self, at: float, note, ring: float, amp: float = 1.0, voice=BELL, glide: float = 0.0):
        """Adds a note at `at` seconds that decays to about -60 dB after `ring` seconds.

        `note` is a name ("A5") or a frequency. `glide` bends the pitch up by that factor over the
        first 60 ms, which turns the pluck into a drop.
        """
        base = hz(note) if isinstance(note, str) else note
        start = int(at * RATE)
        length = min(int(ring * RATE), len(self.samples) - start)
        attack = int(0.004 * RATE)
        for ratio, partial_amp, decay in voice:
            freq = base * ratio
            if freq * (1 + glide) >= RATE / 2:
                continue
            rate = 6.9 / ring * decay      # e^-6.9 ≈ -60 dB
            phase = 0.0
            for i in range(length):
                t = i / RATE
                bend = 1 + glide * (1 - math.exp(-t / 0.02)) if glide else 1
                phase += 2 * math.pi * freq * bend / RATE
                envelope = math.exp(-rate * t)
                if i < attack:
                    envelope *= 0.5 - 0.5 * math.cos(math.pi * i / attack)
                self.samples[start + i] += amp * partial_amp * envelope * math.sin(phase)

    def room(self):
        """Two faint early reflections, so the tones do not sound dry."""
        dry = list(self.samples)
        for delay, gain in ((0.083, 0.16), (0.151, 0.07)):
            offset = int(delay * RATE)
            for i in range(offset, len(dry)):
                self.samples[i] += gain * dry[i - offset]

    def pcm(self) -> bytes:
        self.room()
        # Fade the last 80 ms to silence, so no sound ends in a click.
        fade = int(0.08 * RATE)
        for i in range(fade):
            self.samples[-1 - i] *= i / fade
        loudest = max(abs(s) for s in self.samples)
        scale = PEAK / loudest
        return b"".join(struct.pack("<h", round(s * scale * 32767)) for s in self.samples)


# MARK: - Sounds

def naehe() -> Track:
    """Two tones that meet: a root, then the third and fifth that complete the chord, like the two circles of the icon."""
    track = Track(1.9)
    track.note(0.00, "G5", 1.6, 0.85)
    track.note(0.16, "B5", 1.7, 1.0)
    track.note(0.16, "D6", 1.7, 0.35)
    return track


def funke() -> Track:
    """A quick, bright upward arpeggio."""
    track = Track(1.2)
    for i, note in enumerate(["E6", "G#6", "B6", "E7"]):
        track.note(0.075 * i, note, 0.55 + 0.15 * i, 0.7 + 0.1 * i, voice=PLUCK)
    return track


def tropfen() -> Track:
    """Two water drops, the second one higher."""
    track = Track(0.95)
    track.note(0.00, "C6", 0.35, 0.9, voice=PLUCK, glide=0.45)
    track.note(0.19, "G6", 0.45, 1.0, voice=PLUCK, glide=0.45)
    return track


def morgen() -> Track:
    """A calm, rising pentatonic chime."""
    track = Track(2.4)
    for i, note in enumerate(["D6", "E6", "A6", "B6"]):
        track.note(0.22 * i, note, 1.6, 0.75 + 0.08 * i)
    return track


def gruss() -> Track:
    """A friendly falling "hallo", like a soft doorbell."""
    track = Track(1.8)
    track.note(0.00, "A5", 1.2, 1.0)
    track.note(0.00, "E6", 0.9, 0.25)
    track.note(0.28, "F#5", 1.5, 0.95)
    track.note(0.28, "C#6", 1.0, 0.25)
    return track


FILES = {
    "closer-naehe.wav": naehe,
    "closer-funke.wav": funke,
    "closer-tropfen.wav": tropfen,
    "closer-morgen.wav": morgen,
    "closer-gruss.wav": gruss,
}


# MARK: - Files

def wav(pcm: bytes) -> bytes:
    """A canonical 44-byte-header WAV, written by hand so the bytes do not depend on the `wave` module."""
    header = struct.pack(
        "<4sI4s4sIHHIIHH4sI",
        b"RIFF", 36 + len(pcm), b"WAVE",
        b"fmt ", 16, 1, 1, RATE, RATE * 2, 2, 16,
        b"data", len(pcm),
    )
    return header + pcm


def samples(path: str):
    with wave.open(path, "rb") as f:
        if (f.getnchannels(), f.getsampwidth(), f.getframerate()) != (1, 2, RATE):
            return None
        raw = f.readframes(f.getnframes())
    return struct.unpack(f"<{len(raw) // 2}h", raw)


def main() -> int:
    check = sys.argv[1:] == ["--check"]
    if sys.argv[1:] and not check:
        print(__doc__, file=sys.stderr)
        return 2

    os.makedirs(SOUNDS, exist_ok=True)
    stale = []
    for name, make in FILES.items():
        data = wav(make().pcm())
        seconds = (len(data) - 44) / 2 / RATE
        assert seconds <= MAX_SECONDS, f"{name} is {seconds:.1f} s, iOS allows {MAX_SECONDS} s"
        path = os.path.join(SOUNDS, name)
        if check:
            expected = struct.unpack(f"<{(len(data) - 44) // 2}h", data[44:])
            actual = samples(path) if os.path.exists(path) else None
            if actual is None or len(actual) != len(expected) or any(
                abs(a - b) > TOLERANCE for a, b in zip(actual, expected)
            ):
                stale.append(name)
        else:
            with open(path, "wb") as f:
                f.write(data)

    extra = sorted(set(os.listdir(SOUNDS)) - set(FILES) - {".DS_Store"})
    if check and (stale or extra):
        for name in stale:
            print(f"{name} is out of date")
        for name in extra:
            print(f"{name} is not generated by this script")
        print("Run scripts/generate-notification-sounds.py and commit the result.")
        return 1
    print("Notification sounds up to date" if check else f"Wrote {len(FILES)} sounds to {os.path.relpath(SOUNDS, ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
