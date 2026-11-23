#!/usr/bin/env python3
"""
Convierte las hojas de Autosprite del slime de lava (frames de 128x128) a la hoja del juego.

Entrada (assets/sprites/_source/):
  slime_idle_128.png   4 columnas x 3 filas = 12 frames
  slime_death_128.png  4 columnas x 4 filas = 16 frames (los 4 primeros repiten el idle)
Salida: assets/sprites/enemies/fire_slime.png
  12 columnas x 2 filas de 32x32  ->  fila 0 = idle (12), fila 1 = muerte (12)

Uso:  python3 tools/process_slime_sheets.py   (requiere Pillow y numpy)
"""
import os
import numpy as np
from PIL import Image

BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
SRC = os.path.join(BASE, "_source")
OUT = os.path.join(BASE, "enemies", "fire_slime.png")
FRAME_IN, FRAME_OUT = 128, 32
DEATH_SKIP = 4   # frames iniciales de la muerte que repiten el idle


def slice_sheet(path, cols, rows):
    im = Image.open(path).convert("RGBA")
    frames = []
    for r in range(rows):
        for c in range(cols):
            frames.append(im.crop((c * FRAME_IN, r * FRAME_IN, (c + 1) * FRAME_IN, (r + 1) * FRAME_IN)))
    return frames


def reduce(im, size=FRAME_OUT, thr=110):
    """Reduce con promedio de area (sin halos oscuros) y deja el alfa en 0/255 (pixel art nitido)."""
    a = np.array(im).astype(float)
    al = a[..., 3:4] / 255.0
    pm = np.concatenate([a[..., :3] * al, a[..., 3:4]], axis=2)
    ch = [np.array(Image.fromarray(pm[..., i].astype("uint8")).resize((size, size), Image.BOX)).astype(float)
          for i in range(4)]
    out = np.stack(ch, axis=2)
    alpha = out[..., 3:4]
    rgb = np.where(alpha > 0, out[..., :3] / np.maximum(alpha / 255.0, 1e-3), 0).clip(0, 255)
    alpha = np.where(alpha > thr, 255, 0)
    return Image.fromarray(np.concatenate([rgb, alpha], axis=2).astype("uint8"), "RGBA")


def main():
    idle = [reduce(f) for f in slice_sheet(os.path.join(SRC, "slime_idle_128.png"), 4, 3)]
    death = [reduce(f) for f in slice_sheet(os.path.join(SRC, "slime_death_128.png"), 4, 4)][DEATH_SKIP:]
    n = max(len(idle), len(death))
    sheet = Image.new("RGBA", (FRAME_OUT * n, FRAME_OUT * 2), (0, 0, 0, 0))
    for i, f in enumerate(idle):
        sheet.paste(f, (i * FRAME_OUT, 0))
    for i, f in enumerate(death):
        sheet.paste(f, (i * FRAME_OUT, FRAME_OUT))
    sheet.save(OUT)
    print(f"{os.path.relpath(OUT)}  {sheet.size}  idle={len(idle)} muerte={len(death)}")


if __name__ == "__main__":
    main()
