#!/usr/bin/env python3
"""Genera los recursos sonoros de EXPECTADOOR usando solo la biblioteca estándar.

Produce dos archivos WAV mono de 16 bits en assets/audio/:

  ambient_drone.wav       Textura grave, en bucle sin costuras (32 s).
  anticipation_layer.wav  Capa armónica suspendida que crece con la cercanía (32 s, bucle).

Los bucles se marcan con un bloque 'smpl', que el importador WAV de Godot
detecta automáticamente (modo de bucle "Detect From WAV").

Uso:  python3 tools/generate_audio.py
El resultado es determinista (semilla fija), de modo que se puede regenerar.
"""

import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
LOOP_SECONDS = 32  # Todas las frecuencias de los bucles son múltiplos de 1/32 Hz.
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
TAU = 2.0 * math.pi


def loop_freq(hz: float) -> float:
    """Ajusta una frecuencia para que complete un número entero de ciclos en el bucle."""
    return round(hz * LOOP_SECONDS) / LOOP_SECONDS


def one_pole_lowpass(samples, cutoff_hz):
    alpha = 1.0 - math.exp(-TAU * cutoff_hz / SAMPLE_RATE)
    out = []
    y = 0.0
    for x in samples:
        y += alpha * (x - y)
        out.append(y)
    return out


def looped_noise(n, cutoff_hz, rng, passes=2):
    """Ruido filtrado que enlaza sin costura: se genera de más y se funde la cola con el inicio."""
    fade = SAMPLE_RATE * 2
    raw = [rng.uniform(-1.0, 1.0) for _ in range(n + fade)]
    for _ in range(passes):
        raw = one_pole_lowpass(raw, cutoff_hz)
    out = raw[:n]
    for i in range(fade):
        w = i / fade
        # Fundido de igual potencia entre el comienzo y la continuación natural del final.
        out[i] = raw[i] * math.sin(w * math.pi / 2) + raw[n + i] * math.cos(w * math.pi / 2)
    return out


def normalize(samples, peak):
    m = max(abs(s) for s in samples) or 1.0
    return [s * peak / m for s in samples]


def write_wav(name, samples, loop=False):
    path = os.path.join(OUT_DIR, name)
    frames = b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(frames)
    if loop:
        _append_smpl_chunk(path, 0, len(samples) - 1)
    print(f"  {name}: {len(samples) / SAMPLE_RATE:.1f} s{' (bucle)' if loop else ''}")


def _append_smpl_chunk(path, loop_start, loop_end):
    sample_period = int(1e9 / SAMPLE_RATE)
    header = struct.pack("<9I", 0, 0, sample_period, 60, 0, 0, 0, 1, 0)
    loop = struct.pack("<6I", 0, 0, loop_start, loop_end, 0, 0)  # tipo 0 = bucle hacia delante
    body = header + loop
    with open(path, "r+b") as f:
        f.seek(0, os.SEEK_END)
        f.write(b"smpl" + struct.pack("<I", len(body)) + body)
        riff_size = f.tell() - 8
        f.seek(4)
        f.write(struct.pack("<I", riff_size))


def ambient_drone(rng):
    n = SAMPLE_RATE * LOOP_SECONDS
    partials = [  # (frecuencia, amplitud, periodo del LFO en s, fase)
        (55.0, 0.34, 32, 0.0),
        (82.5, 0.16, 16, 1.3),
        (110.0, 0.10, 32, 2.1),
        (110.5, 0.07, 8, 0.4),   # batido lento con 110 Hz
        (164.8, 0.035, 16, 2.9),
        (220.25, 0.015, 32, 0.8),
    ]
    partials = [(loop_freq(f), a, p, ph) for f, a, p, ph in partials]
    air = looped_noise(n, 260.0, rng)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        s = 0.0
        for f, a, period, ph in partials:
            s += a * (0.8 + 0.2 * math.sin(TAU * t / period + ph)) * math.sin(TAU * f * t)
        breath = 0.75 + 0.25 * math.sin(TAU * t / 16 + 0.5)
        out.append(s + 2.6 * air[i] * breath)
    return normalize(out, 0.7)


def anticipation_layer(rng):
    n = SAMPLE_RATE * LOOP_SECONDS
    # Acorde suspendido (La - Mi - Si) sin resolución, con pares desafinados para dar movimiento.
    voices = [
        (220.0, 0.22, 32, 0.0),
        (220.375, 0.16, 16, 1.0),
        (329.625, 0.17, 16, 2.0),
        (329.9375, 0.12, 32, 0.5),
        (493.875, 0.09, 8, 1.7),
        (494.25, 0.06, 32, 2.6),
        (987.75, 0.018, 4, 0.2),   # brillo muy tenue
    ]
    voices = [(loop_freq(f), a, p, ph) for f, a, p, ph in voices]
    hiss = looped_noise(n, 1800.0, rng, passes=1)
    out = []
    for i in range(n):
        t = i / SAMPLE_RATE
        s = 0.0
        for f, a, period, ph in voices:
            env = 0.55 + 0.45 * math.sin(TAU * t / period + ph) ** 2
            s += a * env * (math.sin(TAU * f * t) + 0.18 * math.sin(TAU * 2 * f * t + ph))
        out.append(s + 0.05 * hiss[i] * (0.5 + 0.5 * math.sin(TAU * t / 8)))
    return normalize(out, 0.6)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    rng = random.Random(1979)
    print("Generando audio de EXPECTADOOR en", os.path.normpath(OUT_DIR))
    write_wav("ambient_drone.wav", ambient_drone(rng), loop=True)
    write_wav("anticipation_layer.wav", anticipation_layer(rng), loop=True)


if __name__ == "__main__":
    main()
