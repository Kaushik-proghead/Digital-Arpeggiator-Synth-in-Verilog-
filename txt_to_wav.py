# txt_to_wav.py
import numpy as np
from scipy.io import wavfile

SAMPLE_RATE = 48000
IN_FILE = "output.txt"
OUT_WAV = "output.wav"

# load samples
data = np.loadtxt(IN_FILE, dtype=np.int32)

# ensure int16 range
data = np.clip(data, -32768, 32767).astype(np.int16)

wavfile.write(OUT_WAV, SAMPLE_RATE, data)
print(f"Wrote {OUT_WAV} ({len(data)} samples at {SAMPLE_RATE} Hz)")
