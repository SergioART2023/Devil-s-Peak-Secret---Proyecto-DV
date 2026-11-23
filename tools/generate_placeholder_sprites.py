#!/usr/bin/env python3
"""
Genera sprites PROVISIONALES (placeholders) en pixel art para Devil's Peak Secret.

Todo el juego usa una rejilla de 16x16 px. Cuando tengan el arte definitivo, basta con
reemplazar los PNG en assets/sprites/ respetando el nombre, el tamaño del frame y el
orden de los frames (ver docs/SPRITES.md). No hace falta tocar el código.

Uso:  python3 tools/generate_placeholder_sprites.py      (requiere Pillow)
"""
import os
import random
from PIL import Image, ImageOps

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")


def hexc(s, a=255):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


def new(w=16, h=16):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def px(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), hexc(c) if isinstance(c, str) else c)


def rect(im, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            px(im, x, y, c)


def hstack(frames):
    w, h = frames[0].size
    out = new(w * len(frames), h)
    for i, f in enumerate(frames):
        out.paste(f, (i * w, 0))
    return out


def vstack(rows):
    w, h = rows[0].size
    out = new(w, h * len(rows))
    for i, r in enumerate(rows):
        out.paste(r, (0, i * h))
    return out


def save(im, *path):
    full = os.path.join(ROOT, *path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    im.save(full)
    print("  ", os.path.relpath(full, os.path.join(ROOT, "..", "..")), im.size)


# ----------------------------------------------------------------- Jacob (jugador)
HAT, HAT_D, BAND = "#7a4a24", "#4a2f18", "#2a1a0e"
SKIN, HAIR, EYE = "#e9b88c", "#3b2616", "#1a1010"
JACKET, JACKET_D, BELT = "#c8a15a", "#9c7a3e", "#5a3a1e"
PANTS, BOOT = "#2e4a7d", "#34200f"
BOW_C, STRING_C = "#8a5a2b", "#e8e0c8"


def jacob(direction, col):
    """direction: down|up|left ; col: 0 idle, 1 paso, 2 ataque espada, 3 ataque arco"""
    im = new()
    step = col == 1
    if direction in ("down", "up"):
        rect(im, 5, 0, 10, 1, HAT)
        rect(im, 5, 2, 10, 2, BAND)
        rect(im, 3, 3, 12, 3, HAT_D)
        if direction == "down":
            rect(im, 5, 4, 10, 7, SKIN)
            px(im, 6, 5, EYE)
            px(im, 9, 5, EYE)
        else:
            rect(im, 5, 4, 10, 7, HAIR)
        rect(im, 4, 8, 11, 10, JACKET)
        rect(im, 4, 11, 11, 11, BELT)
        rect(im, 3, 8, 3, 10, JACKET_D)
        rect(im, 12, 8, 12, 10, JACKET_D)
        px(im, 3, 11, SKIN)
        px(im, 12, 11, SKIN)
        rect(im, 5, 12, 6, 13 if step else 14, PANTS)
        rect(im, 9, 12, 10, 14, PANTS)
        rect(im, 5, 14 if step else 15, 6, 14 if step else 15, BOOT)
        rect(im, 9, 15, 10, 15, BOOT)
        if col in (2, 3):
            if direction == "down":
                rect(im, 7, 12, 8, 14, SKIN)
                if col == 3:
                    rect(im, 4, 14, 11, 14, BOW_C)
                    rect(im, 4, 15, 11, 15, STRING_C)
            else:
                rect(im, 7, 5, 8, 7, SKIN)
                if col == 3:
                    rect(im, 4, 0, 11, 0, BOW_C)
                    rect(im, 4, 1, 11, 1, STRING_C)
    else:  # perfil izquierdo
        rect(im, 4, 0, 9, 1, HAT)
        rect(im, 4, 2, 9, 2, BAND)
        rect(im, 2, 3, 11, 3, HAT_D)
        rect(im, 4, 4, 9, 7, SKIN)
        rect(im, 8, 4, 9, 7, HAIR)
        px(im, 5, 5, EYE)
        px(im, 3, 6, SKIN)
        rect(im, 5, 8, 10, 10, JACKET)
        rect(im, 5, 11, 10, 11, BELT)
        rect(im, 6, 8, 7, 10, JACKET_D)
        rect(im, 6, 12, 7, 13 if step else 14, PANTS)
        rect(im, 8, 12, 9, 14, PANTS)
        rect(im, 5, 14 if step else 15, 7, 14 if step else 15, BOOT)
        rect(im, 8, 15, 10, 15, BOOT)
        if col in (2, 3):
            rect(im, 1, 8, 5, 9, SKIN)
            if col == 3:
                rect(im, 0, 5, 0, 12, BOW_C)
                rect(im, 1, 5, 1, 12, STRING_C)
    return im


def make_player():
    rows = []
    for d in ("down", "up", "left"):
        rows.append(hstack([jacob(d, c) for c in range(4)]))
    right = hstack([ImageOps.mirror(jacob("left", c)) for c in range(4)])
    rows.append(right)
    save(vstack(rows), "player", "jacob.png")

    # Efecto de espada (apunta a la derecha; el juego la rota)
    s = new()
    rect(s, 5, 7, 14, 8, "#d8dde3")
    rect(s, 5, 7, 14, 7, "#f4f7fa")
    px(s, 15, 7, "#f4f7fa")
    px(s, 15, 8, "#d8dde3")
    rect(s, 4, 5, 4, 10, "#d4a017")
    rect(s, 1, 7, 3, 8, "#6b3f1d")
    save(s, "player", "slash.png")


# ----------------------------------------------------------------- Enemigos
def make_slime():
    frames = []
    for f in range(2):
        im = new()
        top = 7 if f == 0 else 8
        left, right = (3, 12) if f == 0 else (2, 13)
        rect(im, left + 1, top, right - 1, 14, "#e8501a")
        rect(im, left, top + 1, right, 14, "#e8501a")
        rect(im, left + 2, top + 1, right - 2, 12, "#ff8a2b")
        rect(im, left + 1, 14, right - 1, 14, "#a82e0c")
        px(im, 6, top + 2, "#ffffff")
        px(im, 9, top + 2, "#ffffff")
        px(im, 6, top + 3, "#1a1010")
        px(im, 9, top + 3, "#1a1010")
        # llama
        rect(im, 7, top - 4, 8, top - 1, "#ffcf3a")
        px(im, 7 + f, top - 5, "#ffe98a")
        px(im, 6, top - 2, "#ff8a2b")
        px(im, 9, top - 2, "#ff8a2b")
        frames.append(im)
    save(hstack(frames), "enemies", "fire_slime.png")


def tiki(direction, shooting):
    im = new()
    WOOD, WOOD_D = "#7a4a2a", "#4a2a14"
    MASK, MASK_D, GOLD = "#c8382a", "#8a2218", "#f2c230"
    GRASS = "#2f7a3a"
    rect(im, 4, 9, 11, 13, WOOD)
    rect(im, 3, 10, 3, 12, WOOD_D)
    rect(im, 12, 10, 12, 12, WOOD_D)
    rect(im, 3, 12, 12, 14, GRASS)
    rect(im, 5, 14, 6, 15, WOOD_D)
    rect(im, 9, 14, 10, 15, WOOD_D)
    if direction == "down":
        rect(im, 3, 1, 12, 8, MASK)
        rect(im, 3, 1, 12, 1, MASK_D)
        rect(im, 5, 3, 6, 4, GOLD)
        rect(im, 9, 3, 10, 4, GOLD)
        px(im, 5, 4, "#1a1010")
        px(im, 10, 4, "#1a1010")
        rect(im, 6, 6, 9, 7 if shooting else 6, "#1a1010")
        if shooting:
            rect(im, 7, 8, 8, 9, "#2a1a0e")
        px(im, 2, 0, "#2f9a4a")
        px(im, 13, 0, "#2f9a4a")
    elif direction == "up":
        rect(im, 3, 1, 12, 8, WOOD)
        rect(im, 3, 1, 12, 1, WOOD_D)
        rect(im, 6, 3, 9, 6, WOOD_D)
        px(im, 2, 0, "#2f9a4a")
        px(im, 13, 0, "#2f9a4a")
    else:  # izquierda
        rect(im, 4, 1, 11, 8, MASK)
        rect(im, 4, 1, 11, 1, MASK_D)
        rect(im, 5, 3, 6, 4, GOLD)
        px(im, 5, 4, "#1a1010")
        rect(im, 2, 6, 3, 6, "#2a1a0e")  # cerbatana
        if shooting:
            rect(im, 0, 6, 3, 6, "#2a1a0e")
            rect(im, 1, 5, 1, 7, "#2a1a0e")
        px(im, 10, 0, "#2f9a4a")
    return im


def make_tiki():
    rows = []
    for d in ("down", "up", "left"):
        rows.append(hstack([tiki(d, False), tiki(d, True)]))
    rows.append(hstack([ImageOps.mirror(tiki("left", False)), ImageOps.mirror(tiki("left", True))]))
    save(vstack(rows), "enemies", "tiki_shooter.png")


# ----------------------------------------------------------------- Proyectiles
def make_projectiles():
    a = new()
    rect(a, 2, 8, 13, 8, "#7a5230")
    px(a, 14, 8, "#c9ced4")
    px(a, 13, 7, "#c9ced4")
    px(a, 13, 9, "#c9ced4")
    for (x, y) in ((1, 7), (1, 9), (2, 7), (2, 9)):
        px(a, x, y, "#d8382a")
    save(a, "projectiles", "arrow.png")
    d = new()
    rect(d, 4, 8, 11, 8, "#2f7d3a")
    px(d, 12, 8, "#e8a030")
    px(d, 3, 8, "#d8d0b0")
    px(d, 3, 7, "#d8d0b0")
    px(d, 3, 9, "#d8d0b0")
    save(d, "projectiles", "dart.png")


# ----------------------------------------------------------------- Tiles
def noisy(base, specks, seed, n=14):
    rnd = random.Random(seed)
    im = new()
    rect(im, 0, 0, 15, 15, base)
    for _ in range(n):
        px(im, rnd.randint(0, 15), rnd.randint(0, 15), rnd.choice(specks))
    return im


def make_tiles():
    save(noisy("#43332f", ["#4d3c37", "#3a2b27", "#483731"], 1), "tiles", "floor_a.png")
    save(noisy("#3f302c", ["#4a3a34", "#352724", "#443530"], 2, 20), "tiles", "floor_b.png")
    save(noisy("#1d1514", ["#241a18", "#181111"], 3, 18), "tiles", "wall_top.png")

    face = new()
    rect(face, 0, 0, 15, 15, "#5b3a2e")
    for row in range(4):
        y = row * 4
        rect(face, 0, y + 3, 15, y + 3, "#2a1913")
        offs = 0 if row % 2 == 0 else 4
        for x in range(offs, 16, 8):
            rect(face, x, y, x, y + 2, "#2a1913")
    rect(face, 0, 0, 15, 0, "#7a4d3a")
    rect(face, 0, 13, 15, 15, "#3a241c")
    save(face, "tiles", "wall_face.png")

    frames = []
    for f in range(2):
        rnd = random.Random(10 + f)
        im = new()
        rect(im, 0, 0, 15, 15, "#c93a12")
        for _ in range(7):
            x, y = rnd.randint(0, 13), rnd.randint(0, 13)
            rect(im, x, y, x + 2, y + 1, "#ff9d1f")
            px(im, x + 1, y, "#ffd24a")
        for _ in range(8):
            px(im, rnd.randint(0, 15), rnd.randint(0, 15), "#8f2509")
        frames.append(im)
    save(hstack(frames), "tiles", "lava.png")

    closed = new()
    rect(closed, 0, 0, 15, 15, "#3b322b")
    rect(closed, 1, 1, 14, 14, "#6f6258")
    for x in range(3, 14, 3):
        rect(closed, x, 2, x, 13, "#2a231e")
    rect(closed, 6, 6, 9, 9, "#d9622b")
    rect(closed, 7, 7, 8, 8, "#ffcf3a")
    opened = new()
    rect(opened, 0, 0, 15, 15, "#3b322b")
    rect(opened, 2, 2, 13, 15, "#0e0909")
    rect(opened, 3, 3, 12, 15, "#1b1110")
    save(hstack([closed, opened]), "tiles", "door.png")

    gate = new()
    for x in (2, 5, 8, 11, 14):
        rect(gate, x, 0, x, 15, "#aab0b8")
        px(gate, x + 1 if x < 15 else x, 4, "#5b6068")
    rect(gate, 0, 2, 15, 2, "#7d838b")
    rect(gate, 0, 13, 15, 13, "#7d838b")
    save(gate, "tiles", "gate.png")

    up = new()
    rect(up, 2, 2, 13, 13, "#3f342d")
    rect(up, 2, 2, 12, 12, "#8a7a6c")
    rect(up, 3, 3, 12, 12, "#6a5b50")
    rect(up, 6, 6, 9, 9, "#4a3d34")
    down = new()
    rect(down, 2, 2, 13, 13, "#8a7a6c")
    rect(down, 2, 2, 12, 12, "#2a211c")
    rect(down, 3, 3, 12, 12, "#3f342d")
    rect(down, 6, 6, 9, 9, "#d9622b")
    save(hstack([up, down]), "tiles", "plate.png")

    blk = new()
    rect(blk, 0, 0, 15, 15, "#5a4a3c")
    rect(blk, 0, 0, 14, 14, "#b09a84")
    rect(blk, 1, 1, 14, 14, "#8d7863")
    rect(blk, 4, 4, 11, 11, "#5a4a3c")
    rect(blk, 5, 5, 11, 11, "#7a6652")
    rect(blk, 7, 6, 8, 9, "#d9622b")
    save(blk, "tiles", "block.png")

    ped = new()
    rect(ped, 3, 6, 12, 14, "#6d6258")
    rect(ped, 3, 14, 12, 14, "#41392f")
    rect(ped, 2, 3, 13, 6, "#8a7e72")
    rect(ped, 2, 3, 13, 3, "#aa9e90")
    save(ped, "tiles", "pedestal.png")

    alt = new()
    rect(alt, 1, 6, 14, 14, "#5a4f46")
    rect(alt, 1, 14, 14, 14, "#3a322b")
    rect(alt, 0, 3, 15, 6, "#7d6f5f")
    rect(alt, 0, 3, 15, 3, "#c9a227")
    rect(alt, 4, 8, 11, 8, "#c9a227")
    save(alt, "tiles", "altar.png")

    sw = []
    for on in (False, True):
        im = new()
        rect(im, 3, 3, 12, 12, "#55616e")
        rect(im, 4, 4, 11, 11, "#3e4853")
        gem = "#4de07a" if on else "#3a7bd5"
        rect(im, 6, 6, 9, 9, gem)
        px(im, 6, 6, "#ffffff")
        if on:
            for (x, y) in ((5, 5), (10, 5), (5, 10), (10, 10)):
                px(im, x, y, "#9cf0b6")
        sw.append(im)
    save(hstack(sw), "tiles", "switch.png")


# ----------------------------------------------------------------- Items y UI
HEART = [
    ".###...###.",
    "#####.#####",
    "###########",
    "###########",
    "###########",
    ".#########.",
    "..#######..",
    "...#####...",
    "....###....",
    ".....#.....",
]


def heart(state):
    """state: 0 vacio, 1 medio, 2 lleno"""
    im = new()
    ox, oy = 2, 3
    mask = {(x, y) for y, r in enumerate(HEART) for x, ch in enumerate(r) if ch == "#"}
    for (x, y) in mask:
        border = any((x + dx, y + dy) not in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if state == 0:
            col = "#4a1a1a" if border else "#2a1010"
        elif state == 2 or (state == 1 and x < 5):
            col = "#7a1010" if border else "#e03030"
            if not border and (x, y) in ((2, 2), (3, 1)):
                col = "#ff9a9a"
        else:
            col = "#4a1a1a" if border else "#2a1010"
        px(im, ox + x, oy + y, col)
    return im


def make_items():
    save(hstack([heart(0), heart(1), heart(2)]), "ui", "hearts.png")
    save(heart(2), "items", "heart.png")

    s = new()
    for i in range(9):
        px(s, 3 + i, 12 - i, "#d8dde3")
        px(s, 4 + i, 12 - i, "#9aa3ad")
    px(s, 12, 3, "#f4f7fa")
    rect(s, 2, 9, 6, 9, "#d4a017")
    px(s, 4, 8, "#d4a017")
    px(s, 4, 10, "#d4a017")
    rect(s, 2, 12, 3, 13, "#6b3f1d")
    save(s, "items", "sword.png")

    b = new()
    for i, (x, y) in enumerate([(5, 2), (4, 3), (3, 4), (3, 5), (3, 6), (3, 7), (3, 8), (3, 9), (4, 10), (5, 11), (6, 12)]):
        px(b, x + 2, y, "#8a5a2b")
        px(b, x + 3, y, "#5a3a1b")
    for y in range(3, 12):
        px(b, 11, y, "#e8e0c8")
    px(b, 8, 7, "#c9ced4")
    px(b, 9, 7, "#c9ced4")
    px(b, 10, 7, "#c9ced4")
    px(b, 7, 7, "#7a5230")
    save(b, "items", "bow.png")

    e = new()
    pts = [(7, 2), (8, 2), (6, 3), (9, 3), (5, 4), (10, 4), (4, 5), (11, 5)]
    rect(e, 5, 4, 10, 11, "#1fae5a")
    rect(e, 4, 5, 11, 9, "#1fae5a")
    rect(e, 6, 3, 9, 3, "#2fd070")
    rect(e, 6, 12, 9, 12, "#0f7a3a")
    rect(e, 5, 11, 10, 11, "#0f7a3a")
    rect(e, 6, 5, 7, 6, "#9cf0b6")
    px(e, 6, 5, "#ffffff")
    rect(e, 8, 8, 9, 10, "#0f8a45")
    save(e, "items", "emerald.png")


def main():
    print("Generando sprites provisionales en", os.path.normpath(ROOT))
    make_player()
    # El slime definitivo se genera con tools/process_slime_sheets.py (no se sobreescribe).
    make_tiki()
    make_projectiles()
    make_tiles()
    make_items()
    print("Listo.")


if __name__ == "__main__":
    main()
