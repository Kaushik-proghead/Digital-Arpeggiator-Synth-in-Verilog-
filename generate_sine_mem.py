# generate_sine_mem.py
import numpy as np

SAMPLES = 256
AMPLITUDE = int(0.9 * 32767)   # 90% of int16 max
SAMPLE_RATE = 48000
PHASE_WIDTH = 32

# common note frequencies (octave numbers as integer)
NOTE_FREQS = {
    "C3":130.813, "C#3":138.591, "D3":146.832, "D#3":155.563, "E3":164.814, "F3":174.614,
    "F#3":184.997, "G3":195.998, "G#3":207.652, "A3":220.0, "A#3":233.082, "B3":246.942,
    "C4":261.626, "C#4":277.183, "D4":293.665, "D#4":311.127, "E4":329.628, "F4":349.228,
    "F#4":369.994, "G4":391.995, "G#4":415.305, "A4":440.0, "A#4":466.164, "B4":493.883,
    "C5":523.251, "C#5":554.365, "D5":587.33, "D#5":622.254, "E5":659.255, "F5":698.456
}

def build_sine_mem(filename="sine256.mem"):
    t = np.arange(SAMPLES)
    sine = (AMPLITUDE * np.sin(2 * np.pi * t / SAMPLES)).astype(np.int16)
    with open(filename, "w") as f:
        for v in sine:
            f.write("{:04x}\n".format(np.uint16(v) & 0xFFFF))
    print(f"Wrote {filename} ({SAMPLES} samples).")

def delta_for_freq(freq, sample_rate=SAMPLE_RATE, phase_width=PHASE_WIDTH):
    return int(round(freq * (2**phase_width) / sample_rate))

def print_example_deltas():
    print("\nExample delta values (phase width = {}, sample_rate = {} Hz):".format(PHASE_WIDTH, SAMPLE_RATE))
    # print a subset of notes
    notes = ["C4","D#4","F4","G4","A4","A#3","C5","D5","G#3","C3","D3"]
    for n in notes:
        if n in NOTE_FREQS:
            print(f"{n:4} {NOTE_FREQS[n]:7.3f} Hz  -> delta = {delta_for_freq(NOTE_FREQS[n])} (0x{delta_for_freq(NOTE_FREQS[n]):08X})")
    # also print user-request example: Eb4, Bb3 etc
    custom = {"Eb4":311.127, "Bb3":233.082, "Ab3":207.652}
    print("\nCustom (Clocks/other) deltas:")
    for name,f in custom.items():
        print(f"{name:4} {f:7.3f} Hz -> delta = {delta_for_freq(f)} (0x{delta_for_freq(f):08X})")

if __name__ == "__main__":
    build_sine_mem("sine256.mem")
    print_example_deltas()
    print("\nTo compute delta for any frequency f (Hz):")
    print("  delta = round(f * 2^32 / 48000)")

