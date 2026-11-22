# Diseño de salas (planos ASCII)

Cada sala vive en `scripts/room_data.gd` como 16 filas de 30 caracteres (casillas de 16 px → 480×256 px).
Editar el texto y volver a correr el juego basta para rediseñar una sala.

| Carácter | Significado |
|---|---|
| `#` | Pared (la cara frontal se dibuja sola) |
| `.` | Piso |
| `~` | Lava (quita 1 de vida y devuelve al último suelo seguro). Un bloque empujado dentro la tapa |
| `a` `b` | Puntos de aparición (`a` = entrada principal, `b` = entrada de regreso) |
| `1` `2` … | Puerta de salida. Su destino está en `"exits"` (`room`, `spawn`) |
| `g` | Compuerta (se abre al resolver el puzzle) |
| `B` | Bloque empujable/halable |
| `T` | Placa de presión (se activa con un bloque encima) |
| `S` | Interruptor (solo con flecha) |
| `W` `R` `E` `H` | Espada, arco, esmeralda, corazón |
| `m` `k` | Slime de fuego / hombre tiki (solo salas de combate) |

Propiedades de sala: `type` (`free`, `puzzle`, `combat`), `locked_exits` (salidas bloqueadas hasta resolver),
`requires_item` (objeto necesario además del puzzle), `fill_on_solved` (lava que queda tapada al resolver), `hint`.

Destinos especiales: `@ending` (final oculto), `@demo_end` (fin de la primera entrega).

## Mapa actual
temple →(esmeralda: caída)→ room_01 (bloques → **espada**) → room_02 (combate) → room_03 (lava+bloques → **arco**)
→ room_04 (interruptores con flechas) → room_05 (combate) → fin de demo.
El arco está dos salas después de la espada, como pide el diseño.
