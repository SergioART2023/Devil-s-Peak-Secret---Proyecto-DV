# Devil's Peak Secret

RPG 2D top-down de exploración y puzzles dentro de un templo volcánico.
Proyecto del curso **Desarrollo de Videojuegos** – Universidad del Valle.

**Autores:** Jonathan Aristizabal Vargas · Sergio Rodriguez Trujillo
**Motor:** Godot **4.7.2** (versión estándar, GDScript) · Renderer: GL Compatibility
**Primera entrega:** 25 de noviembre de 2026 · **Presentación:** 11 de diciembre de 2026

## Cómo abrir el proyecto
1. Descargar Godot 4.7.2 (o superior 4.7.x) desde https://godotengine.org/download
2. Clonar el repo, abrir Godot → *Import* → seleccionar `project.godot`.
3. La primera vez Godot importa los PNG (unos segundos). Ejecutar con **F5**.

## Controles
| Acción | Teclas |
|---|---|
| Mover | WASD / Flechas |
| Espada | J / Espacio |
| Arco | K / X |
| Agarrar bloque (mantener) | E / Shift: avanzar = empujar, retroceder = halar |
| Reiniciar sala (si un bloque se atasca) | R |
| Volver al menú | Esc |

Caminar contra un bloque también lo empuja una casilla.

## Estado de la primera entrega
- Intro del templo con la esmeralda (si no la tomas → **final oculto**; si la tomas → cae al nivel).
- 5 salas jugables: acertijo de bloques → espada, combate, lava + bloques → arco, interruptores con flechas, combate final.
- Enemigos: slime de fuego (persigue) y hombre tiki (dispara dardos).
- Salas de combate cierran puertas hasta vencer a todos; salas de puzzle bloquean la salida hasta resolver.
- Vida (3 corazones), derrota con reintento, transiciones, HUD, menú.
- Música: pendiente (no se califica en la primera entrega).
- Final oculto: pantalla provisional; el video va en `assets/video/final_oculto.ogv` (Ogg Theora).

## Estructura
```
project.godot
scripts/        game.gd (autoload), room.gd, room_data.gd, player.gd, enemy*.gd, hud.gd ...
scenes/         game.tscn, player.tscn, objects/, enemies/, projectiles/, ui/
assets/sprites/ PNG (provisionales, ver docs/SPRITES.md)
assets/video/   final_oculto.ogv (pendiente)
docs/           DISENO_SALAS.md, SPRITES.md, ARQUITECTURA.md
tests/          smoke_test (pruebas automáticas) y screenshot
tools/          generador de sprites provisionales
```

## Probar una sala directamente
```
godot --path . -- --room=room_03
```
(Entrega la espada/arco que el jugador tendría en esa sala.) Salas: `temple, room_01 … room_05`.

## Pruebas automáticas
```
godot --headless --path . res://tests/smoke_test.tscn
```
Simula empujar/halar, lava, combate, interruptores y la secuencia de caída (51 comprobaciones).

## Flujo de trabajo con Git
- Rama `main` siempre abre y corre. Trabajar en ramas `feature/<tema>` y hacer PR/merge.
- Los `.tscn` y `.import` **sí** se versionan; la carpeta `.godot/` no.
- Evitar editar la misma escena a la vez; avisar al otro antes de tocar `room.gd`/`player.gd`.
