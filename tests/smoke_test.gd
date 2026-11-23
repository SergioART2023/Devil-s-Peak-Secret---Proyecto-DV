extends Node
## Prueba de humo automatica. Ejecutar con:
##   godot --headless --path . res://tests/smoke_test.tscn
## Simula entradas y comprueba las mecanicas principales (puzzles, combate, lava, transiciones).

var failures := 0
var checks := 0


func check(cond: bool, msg: String) -> void:
	checks += 1
	if cond:
		print("  ok   - ", msg)
	else:
		failures += 1
		print("  FAIL - ", msg)


func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func make_room(id: String, spawn: String = "a") -> Room:
	var p: Player = load("res://scenes/player.tscn").instantiate()
	var r := Room.new()
	r.room_id = id
	r.spawn_key = spawn
	r.player = p
	get_tree().root.add_child(r)
	return r


func drop(r: Room) -> void:
	r.entities.remove_child(r.player)
	r.player.free()
	r.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	print("== 1. Todas las salas cargan ==")
	for id in RoomData.ORDER:
		Game.reset_run()
		var r := make_room(id)
		await wait(0.1)
		check(r.grid.size() == 16 and r.grid[0].size() == 30, "%s: rejilla 30x16" % id)
		check(r.spawns.has("a"), "%s: tiene punto de aparicion 'a'" % id)
		await drop(r)

	print("== 2. Sala 1: acertijo de bloques abre compuerta; la puerta pide la espada ==")
	Game.reset_run()
	var r1 := make_room("room_01")
	await wait(0.1)
	check(r1.blocks.size() == 2 and r1.plates.size() == 2, "2 bloques y 2 placas")
	check(not r1.puzzle_done, "puzzle sin resolver al inicio")
	check(r1.char_at(Vector2i(14, 2)) == "g", "compuerta cerrada bloquea la espada")
	r1.blocks[0].setup(r1, r1.plates[0])
	await wait(0.1)
	check(not r1.puzzle_done, "con una sola placa no se resuelve")
	r1.blocks[1].setup(r1, r1.plates[1])
	await wait(0.2)
	check(r1.puzzle_done, "con las dos placas se resuelve")
	check(Game.solved_rooms.has("room_01"), "progreso guardado en Game")
	check(r1.char_at(Vector2i(14, 2)) == ".", "casilla de la compuerta transitable")
	check(not r1.doors["1"][0].is_open, "puerta sigue cerrada sin espada")
	Game.give_item("sword")
	await wait(0.1)
	check(r1.doors["1"][0].is_open, "puerta se abre al obtener la espada")
	await drop(r1)

	print("== 3. Empujar caminando contra un bloque ==")
	Game.reset_run()
	var r3 := make_room("room_01")
	await wait(0.1)
	var blk: Block = r3.block_at(Vector2i(6, 4))
	r3.player.global_position = r3.cell_to_pos(Vector2i(4, 4))
	r3.player.invuln = 0.0
	Input.action_press("move_right")
	await wait(1.2)
	Input.action_release("move_right")
	await wait(0.3)
	check(blk.cell.x >= 7, "el bloque avanzo al empujarlo (celda x=%d)" % blk.cell.x)
	await drop(r3)

	print("== 4. Agarrar con E: empujar y halar ==")
	Game.reset_run()
	var r4 := make_room("room_01")
	await wait(0.1)
	var b2: Block = r4.block_at(Vector2i(6, 10))
	r4.player.global_position = r4.cell_to_pos(Vector2i(6, 11))
	r4.player.facing = Vector2i.UP
	Input.action_press("grab")
	Input.action_press("move_up")
	await wait(0.1)
	Input.action_release("move_up")
	await wait(0.5)
	check(b2.cell == Vector2i(6, 9), "empujar con E: bloque en (6,9) -> %s" % str(b2.cell))
	check(r4.pos_to_cell(r4.player.global_position) == Vector2i(6, 10), "el jugador avanzo con el bloque")
	Input.action_press("move_down")
	await wait(0.1)
	Input.action_release("move_down")
	await wait(0.5)
	Input.action_release("grab")
	check(b2.cell == Vector2i(6, 10), "halar con E: bloque vuelve a (6,10) -> %s" % str(b2.cell))
	check(r4.pos_to_cell(r4.player.global_position) == Vector2i(6, 11), "el jugador retrocedio")
	await drop(r4)

	print("== 5. Lava: quema al jugador y un bloque la tapa ==")
	Game.reset_run()
	var r5 := make_room("room_03")
	await wait(0.1)
	r5.player.invuln = 0.0
	var before := Game.hp
	r5.player.global_position = r5.cell_to_pos(Vector2i(14, 5))
	await wait(0.2)
	check(Game.hp == before - 1, "la lava resta 1 de vida")
	check(not r5.is_lava(r5.pos_to_cell(r5.player.global_position + Vector2(0, 3))), "el jugador vuelve a suelo seguro")
	var lb: Block = r5.block_at(Vector2i(6, 4))
	lb.setup(r5, Vector2i(13, 8))
	check(r5.is_lava(Vector2i(14, 8)), "(14,8) es lava")
	lb.try_push(Vector2i.RIGHT)
	await wait(0.5)
	check(not r5.is_lava(Vector2i(14, 8)), "el bloque tapo la lava")
	check(r5.blocks.size() == 1, "el bloque usado desaparece")
	await drop(r5)

	print("== 6. Combate: puertas se cierran y se abren al vencer ==")
	Game.reset_run()
	Game.give_item("sword")
	var r6 := make_room("room_02")
	await wait(0.1)
	check(r6.state == Room.State.WAITING, "sala de combate esperando al jugador")
	check(r6.doors["1"][0].is_open and r6.doors["2"][0].is_open, "puertas abiertas al entrar")
	r6.player.global_position = r6.cell_to_pos(Vector2i(7, 7))
	await wait(0.3)
	check(r6.state == Room.State.COMBAT, "empieza el combate al alejarse de la entrada")
	check(not r6.doors["1"][0].is_open and not r6.doors["2"][0].is_open, "puertas cerradas en combate")
	var foes := get_tree().get_nodes_in_group("enemy")
	check(foes.size() == 5, "5 enemigos aparecen (%d)" % foes.size())
	r6.player.invuln = 99.0
	await wait(3.0)
	for e in get_tree().get_nodes_in_group("enemy"):
		e.take_damage(9, r6.player.global_position)
	await wait(0.6)
	check(r6.state == Room.State.DONE, "sala despejada")
	check(Game.cleared_rooms.has("room_02"), "progreso de combate guardado")
	check(r6.doors["1"][0].is_open and r6.doors["2"][0].is_open, "puertas abiertas tras vencer")
	await drop(r6)

	print("== 7. Espada, arco y dano por contacto ==")
	Game.reset_run()
	Game.give_item("sword")
	Game.give_item("bow")
	var r7 := make_room("room_05")
	await wait(0.1)
	r7.state = Room.State.DONE     # evita iniciar el combate real
	var pl := r7.player
	pl.global_position = r7.cell_to_pos(Vector2i(5, 12))
	pl.facing = Vector2i.RIGHT
	var slime: FireSlime = load("res://scenes/enemies/fire_slime.tscn").instantiate()
	slime.position = pl.global_position + Vector2(14, 0)
	r7.entities.add_child(slime)       # sin setup(): no persigue al jugador
	await wait(0.1)
	Input.action_press("attack")
	await wait(0.08)
	Input.action_release("attack")
	await wait(0.4)
	check(slime.hp == 1, "la espada dana al slime (hp=%d)" % slime.hp)
	await wait(0.5)
	slime.global_position = pl.global_position + Vector2(90, 0)
	await wait(0.1)
	Input.action_press("bow")
	await wait(0.08)
	Input.action_release("bow")
	await wait(1.0)
	check(not is_instance_valid(slime) or slime.dead, "la flecha mata al slime")
	var hp0 := Game.hp
	var s2: FireSlime = load("res://scenes/enemies/fire_slime.tscn").instantiate()
	s2.position = pl.global_position
	r7.entities.add_child(s2)
	s2.setup(pl)
	pl.invuln = 0.0
	await wait(0.3)
	check(Game.hp == hp0 - 1, "el contacto con un enemigo quita 1 de vida")
	await drop(r7)

	print("== 8. Sala 4: dos flechas a los interruptores abren las compuertas ==")
	Game.reset_run()
	Game.give_item("bow")
	var r8 := make_room("room_04")
	await wait(0.1)
	check(r8.switches.size() == 2 and not r8.puzzle_done, "2 interruptores sin activar")
	var arrow_scene: PackedScene = load("res://scenes/projectiles/arrow.tscn")
	for row in [3, 12]:
		var a: Arrow = arrow_scene.instantiate()
		a.direction = Vector2.RIGHT
		r8.add_child(a)
		a.global_position = r8.cell_to_pos(Vector2i(10, row))
		await wait(0.1)
	await wait(1.0)
	check(r8.puzzle_done, "ambos interruptores activados -> puzzle resuelto")
	check(r8.gates.size() == 4 and r8.gates[0].is_open, "compuertas abiertas")
	await drop(r8)

	print("== 9. Escena de juego: caida, transiciones y menus ==")
	Game.reset_run()
	var gs: Node = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child(gs)
	await wait(1.0)
	check(gs.current_room_id == "temple", "el juego inicia en el templo")
	Game.give_item("emerald")
	await wait(4.5)
	check(gs.current_room_id == "room_01", "al tomar la esmeralda Jacob cae a la sala 1")
	check(gs.player.state == Player.State.NORMAL, "el jugador recupera el control")
	gs._on_exit_requested("room_02", "a")
	await wait(1.0)
	check(gs.current_room_id == "room_02", "transicion a la sala 2")
	gs.queue_free()
	await get_tree().process_frame
	for path in ["res://scenes/ui/main_menu.tscn", "res://scenes/ui/ending.tscn"]:
		var s: Node = load(path).instantiate()
		get_tree().root.add_child(s)
		await wait(0.2)
		check(s.get_child_count() > 0, "%s carga" % path)
		s.queue_free()
		await get_tree().process_frame
	Game.ending_kind = "demo"

	print("\n%d comprobaciones, %d fallos" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)
