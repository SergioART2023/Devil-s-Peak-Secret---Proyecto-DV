#!/usr/bin/env python3
"""Empaqueta los frames originales del slime de Autosprite. Requiere Pillow."""
from pathlib import Path

from PIL import Image

BASE = Path(__file__).resolve().parent.parent / "assets" / "sprites"
FRAME = 128
COLUMNS = 12


def main():
    sheet = Image.new("RGBA", (FRAME * COLUMNS, FRAME * 2))
    for row, (name, skip) in enumerate((("idle", 0), ("death", 4))):
        with Image.open(BASE / "_source" / f"slime_{name}_128.png") as source:
            for column in range(COLUMNS):
                source_row, source_column = divmod(column + skip, 4)
                x, y = source_column * FRAME, source_row * FRAME
                frame = source.crop((x, y, x + FRAME, y + FRAME))
                sheet.paste(frame, (column * FRAME, row * FRAME))
    sheet.save(BASE / "enemies" / "fire_slime.png")


if __name__ == "__main__":
    main()
