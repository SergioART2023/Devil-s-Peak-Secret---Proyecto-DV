# Arquitectura

- **Game (autoload, `game.gd`)**: vida, inventario, progreso (`solved_rooms`, `cleared_rooms`, `taken_items`), acciones de entrada.
- **game_scene.gd** (`game.tscn`): carga salas, transiciones con fundido, secuencia de caída, derrota/reintento.
- **Room (`room.gd`)**: construye la sala desde `RoomData`; gestiona puertas, compuertas, bloques (rejilla), placas, interruptores,
  lava, objetos y la máquina de estados del combate (`WAITING → COMBAT → DONE`).
- **Player**: máquina de estados `NORMAL/ATTACK/SHOOT/PULL/DEAD/LOCKED`; empuje por colisión y agarre con E sobre la rejilla.
- **Enemy** (base) → `FireSlime`, `TikiShooter` (sobrescriben `_ai`). Proyectiles: `Arrow`, `Dart`.
- **Capas de colisión**: 1 sólidos (paredes, puertas, bloques) · 2 jugador · 3 enemigos · 4 interruptores.
- **Patrones**: herencia (Enemy), máquina de estados (Player/Room), observer (señales de Game), datos separados de la lógica (RoomData).
