# Guía de sprites

Todo está en rejilla de **16×16 px**, pixel art, fondo transparente. Los PNG actuales son provisionales
(`tools/generate_placeholder_sprites.py`). Para reemplazar uno: mismo nombre de archivo, mismo tamaño de frame y orden.
Si generas arte con IA, pídelo a 64×64 o 128×128 y redúcelo a 16×16 con interpolación *nearest*, o usa packs
gratuitos (itch.io / OpenGameArt, revisando la licencia) y recórtalos a esta rejilla.

| Archivo | Tamaño | Contenido / orden de frames |
|---|---|---|
| `player/jacob.png` | 64×64 | 4 filas (abajo, arriba, izquierda, derecha) × 4 columnas (quieto, paso, ataque espada, ataque arco) |
| `player/slash.png` | 16×16 | Espada/tajo apuntando a la **derecha** (el juego lo rota) |
| `enemies/fire_slime.png` | 32×16 | 2 frames de rebote |
| `enemies/tiki_shooter.png` | 32×64 | 4 filas (abajo, arriba, izq., der.) × 2 columnas (quieto, soplando) |
| `projectiles/arrow.png`, `dart.png` | 16×16 | Apuntan a la derecha |
| `tiles/floor_a/b.png`, `wall_top.png`, `wall_face.png` | 16×16 | Piso (2 variantes), tope de pared y cara frontal |
| `tiles/lava.png` | 32×16 | 2 frames animados |
| `tiles/door.png` | 32×16 | cerrada, abierta |
| `tiles/gate.png`, `block.png`, `pedestal.png`, `altar.png` | 16×16 | |
| `tiles/plate.png`, `switch.png` | 32×16 | suelta/pulsada · apagado/encendido |
| `items/sword|bow|emerald|heart.png` | 16×16 | Iconos de objeto |
| `ui/hearts.png` | 48×16 | vacío, medio, lleno |

Pendiente para próximas entregas: tileset volcánico definitivo, jefe, más enemigos, animación de muerte/caída, música y SFX.
