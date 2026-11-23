class_name Room
extends Node2D
## Construye una sala a partir de su plano ASCII (ver room_data.gd) y gestiona su logica:
## puertas, compuertas, bloques, placas, interruptores, lava, objetos y combate.

signal exit_requested(target_room: String, target_spawn: String)

const TILE := 32
const COLS := 30
const ROWS := 16

const DOOR_SCENE := preload("res://scenes/objects/door.tscn")
const BLOCK_SCENE := preload("res://scenes/objects/block.tscn")
const PICKUP_SCENE := preload("res://scenes/objects/pickup.tscn")
const SWITCH_SCENE := preload("res://scenes/objects/arrow_switch.tscn")
const SLIME_SCENE := preload("res://scenes/enemies/fire_slime.tscn")
const TIKI_SCENE := preload("res://scenes/enemies/tiki_shooter.tscn")

const TEX_FLOOR_A := preload("res://assets/sprites/tiles/floor_a.png")
const TEX_FLOOR_B := preload("res://assets/sprites/tiles/floor_b.png")
const TEX_WALL_TOP := preload("res://assets/sprites/tiles/wall_top.png")
const TEX_WALL_FACE := preload("res://assets/sprites/tiles/wall_face.png")
const TEX_LAVA := preload("res://assets/sprites/tiles/lava.png")
const TEX_PLATE := preload("res://assets/sprites/tiles/pressure_plate.png")
const TEX_PEDESTAL := preload("res://assets/sprites/tiles/pedestal.png")
const TEX_ALTAR := preload("res://assets/sprites/tiles/altar.png")

enum State { IDLE, WAITING, COMBAT, DONE }

var room_id: String = ""
var spawn_key: String = "a"
var player: Player

var data: Dictionary = {}
var grid: Array = []                 # grid[y][x] -> caracter de la casilla
var state: State = State.IDLE
var puzzle_done := false
var entry_pos := Vector2.ZERO
var enemies_alive := 0

var doors: Dictionary = {}           # clave de salida ("1","2") -> Array[Door]
var gates: Array = []
var blocks: Array = []
var plates: Array = []               # Vector2i
var plates_pressed: Dictionary = {}
var switches: Array = []
var enemy_spawns: Array = []         # {"cell": Vector2i, "kind": String}
var spawns: Dictionary = {}

var entities: Node2D
var structures: Node2D
var lava_frame := 0
var _lava_timer := 0.0
var _has_lava := false
var _unlock_announced := false
var _is_manual := false
var plate_sprites: Dictionary = {}


func _ready() -> void:
	if room_id == "":
		room_id = "room_01"
	data = RoomData.ROOMS.get(room_id, {"name": name, "type": "free", "exits": {}})
	_is_manual = has_node("TileMapLayer")
	if _is_manual:
		_setup_manual_scene()
	else:
		structures = Node2D.new()
		structures.name = "Structures"
		add_child(structures)
		entities = Node2D.new()
		entities.name = "Entities"
		entities.y_sort_enabled = true
		add_child(entities)

		_parse_layout()
		_build_walls()

	_apply_initial_state()
	_place_player()
	Game.item_collected.connect(_on_item_collected)
	if not _is_manual:
		queue_redraw()


# --- Utilidades de rejilla ------------------------------------------------------------------
func cell_to_pos(c: Vector2i) -> Vector2:
	return Vector2(c.x * TILE + TILE / 2.0, c.y * TILE + TILE / 2.0)


func pos_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / TILE), floori(p.y / TILE))


func char_at(c: Vector2i) -> String:
	if c.x < 0 or c.y < 0 or c.x >= COLS or c.y >= ROWS:
		return "#"
	return grid[c.y][c.x]


func is_lava(c: Vector2i) -> bool:
	return char_at(c) == "~"


func block_at(c: Vector2i) -> Block:
	for b in blocks:
		if is_instance_valid(b) and b.cell == c:
			return b
	return null


## Casilla en la que el jugador puede estar (usado al halar bloques).
func is_cell_walkable(c: Vector2i) -> bool:
	var ch := char_at(c)
	if ch in ["#", "~", "g", "S"] or ch.is_valid_int():
		return false
	return block_at(c) == null


## Casilla a la que puede moverse un bloque. La lava SI se permite (el bloque la tapa).
func can_block_enter(c: Vector2i, ignore_player: bool = false) -> bool:
	var ch := char_at(c)
	if ch in ["#", "g", "S", "P", "A"] or ch.is_valid_int():
		return false
	if block_at(c) != null:
		return false
	if not ignore_player and player != null and pos_to_cell(player.global_position) == c:
		return false
	return true


func fill_lava(c: Vector2i, block: Block) -> void:
	grid[c.y][c.x] = "."
	blocks.erase(block)
	queue_redraw()


# --- Construccion ---------------------------------------------------------------------------
func _setup_manual_scene() -> void:
	var solved := Game.solved_rooms.has(room_id)
	structures = get_node_or_null("Structures")
	if structures == null:
		structures = Node2D.new()
		structures.name = "Structures"
		add_child(structures)
	entities = get_node_or_null("Entities")
	if entities == null:
		entities = Node2D.new()
		entities.name = "Entities"
		entities.y_sort_enabled = true
		add_child(entities)

	# Inicializar rejilla con bordes solidos y centro transitable
	for y in ROWS:
		var row: Array = []
		for x in COLS:
			var is_border := x == 0 or y == 0 or x == COLS - 1 or y == ROWS - 1
			row.append("#" if is_border else ".")
		grid.append(row)

	# Puntos de spawn (ignorar si quedaron en (0, 0) sin colocar)
	if has_node("Spawns"):
		for marker in $Spawns.get_children():
			if marker is Node2D and marker.position != Vector2.ZERO:
				spawns[String(marker.name)] = marker.position

	# Puertas, compuertas e interruptores
	for child in structures.get_children():
		if child is Door:
			var c := pos_to_cell(child.position)
			if child.kind == "gate":
				gates.append(child)
				if not solved and c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS:
					grid[c.y][c.x] = "g"
			else:
				child.entered.connect(_on_door_entered)
				if not doors.has(child.exit_key):
					doors[child.exit_key] = []
				doors[child.exit_key].append(child)
				var door_key: String = str(child.exit_key) if child.exit_key != "" else "."
				var cs: CollisionShape2D = child.get_node_or_null("CollisionShape2D") as CollisionShape2D
				if cs != null and cs.shape is RectangleShape2D:
					var half: Vector2 = (cs.shape as RectangleShape2D).size * 0.5 * child.scale.abs()
					var center: Vector2 = child.position + cs.position * child.scale
					var c_min := pos_to_cell(center - half)
					var c_max := pos_to_cell(center + half)
					for cy in range(maxi(c_min.y, 0), mini(c_max.y, ROWS - 1) + 1):
						for cx in range(maxi(c_min.x, 0), mini(c_max.x, COLS - 1) + 1):
							grid[cy][cx] = door_key
				elif c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS:
					grid[c.y][c.x] = door_key
		elif child is ArrowSwitch:
			child.active = solved
			switches.append(child)

	# Placas de presion (se dibuja el sprite encima del TileMapLayer)
	if has_node("Plates"):
		for marker in $Plates.get_children():
			if marker is Node2D:
				var c := pos_to_cell(marker.position)
				if c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS:
					plates.append(c)
					grid[c.y][c.x] = "T"
					var spr := Sprite2D.new()
					spr.texture = TEX_PLATE
					spr.modulate = Color(0.75, 0.9, 0.75) if solved else Color.WHITE
					spr.position = cell_to_pos(c)
					structures.add_child(spr)
					plate_sprites[c] = spr
					if solved:
						plates_pressed[c] = true

	# Obstaculos manuales (pilares, braseros, rocas): bloquear tambien sus casillas en la rejilla
	var obs_node := get_node_or_null("Obstacles")
	if obs_node == null:
		obs_node = entities.get_node_or_null("Obstacles")
	if obs_node != null:
		for obs in obs_node.get_children():
			if obs is StaticBody2D:
				var c := pos_to_cell(obs.position)
				if c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS:
					grid[c.y][c.x] = "#"

	# Bloques y objetos en Entities (si ya estaba resuelta, aparecen encima de las placas)
	var block_idx := 0
	for child in entities.get_children():
		if child is Block:
			var target_cell: Vector2i = pos_to_cell(child.position)
			var on_plate := false
			if solved and block_idx < plates.size():
				target_cell = plates[block_idx]
				on_plate = true
			child.setup(self, target_cell)
			child.set_lit(on_plate)
			blocks.append(child)
			block_idx += 1

	_build_walls()


func _parse_layout() -> void:
	var solved := Game.solved_rooms.has(room_id)
	var cleared := Game.cleared_rooms.has(room_id)
	var fill_cells: Array = []
	for f in data.get("fill_on_solved", []):
		fill_cells.append(Vector2i(f[0], f[1]))
	var layout: Array = data["layout"]
	var pickups := {"W": "sword", "R": "bow", "E": "emerald", "H": "heart"}

	for y in ROWS:
		var row: Array = []
		var line: String = layout[y]
		for x in COLS:
			var ch: String = line[x]
			var cell := Vector2i(x, y)
			var store := ch
			match ch:
				"a", "b", "c", "d":
					spawns[ch] = cell_to_pos(cell)
					store = "."
				"B":
					store = "."
					if not solved:
						_spawn_block(cell)
				"T":
					if solved:
						store = "."
					else:
						plates.append(cell)
				"S":
					_spawn_switch(cell, solved)
				"g":
					_spawn_door(cell, "gate", "")
					if solved:
						store = "."
				"~":
					if solved and cell in fill_cells:
						store = "."
					else:
						_has_lava = true
				"m", "k":
					store = "."
					if not cleared:
						enemy_spawns.append({"cell": cell, "kind": ch})
				"W", "R", "E", "H":
					store = "A" if ch == "E" else ("." if ch == "H" else "P")
					_spawn_pickup(cell, pickups[ch])
				_:
					if ch.is_valid_int():
						_spawn_door(cell, "door", ch)
			row.append(store)
		grid.append(row)


func _spawn_door(cell: Vector2i, kind: String, key: String) -> void:
	var d: Door = DOOR_SCENE.instantiate()
	d.kind = kind
	d.exit_key = key
	d.position = cell_to_pos(cell)
	structures.add_child(d)
	if kind == "gate":
		gates.append(d)
	else:
		d.entered.connect(_on_door_entered)
		if not doors.has(key):
			doors[key] = []
		doors[key].append(d)


func _spawn_block(cell: Vector2i) -> void:
	var b: Block = BLOCK_SCENE.instantiate()
	b.setup(self, cell)
	entities.add_child(b)
	blocks.append(b)


func _spawn_switch(cell: Vector2i, solved: bool) -> void:
	var s: ArrowSwitch = SWITCH_SCENE.instantiate()
	s.position = cell_to_pos(cell)
	s.active = solved
	structures.add_child(s)
	switches.append(s)


func _spawn_pickup(cell: Vector2i, item: String) -> void:
	var key := "%s:%d,%d" % [room_id, cell.x, cell.y]
	if Game.taken_items.has(key):
		return
	var p: Pickup = PICKUP_SCENE.instantiate()
	p.item_id = item
	p.key = key
	p.position = cell_to_pos(cell)
	entities.add_child(p)


## Fusiona las casillas de pared en pocos rectangulos (evita que el jugador se "enganche").
func _build_walls() -> void:
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var visited: Array = []
	for y in ROWS:
		visited.append([])
		for x in COLS:
			visited[y].append(false)
	for y in ROWS:
		for x in COLS:
			if grid[y][x] != "#" or visited[y][x]:
				continue
			var w := 1
			while x + w < COLS and grid[y][x + w] == "#" and not visited[y][x + w]:
				w += 1
			var h := 1
			var can_grow := true
			while can_grow and y + h < ROWS:
				for i in w:
					if grid[y + h][x + i] != "#" or visited[y + h][x + i]:
						can_grow = false
						break
				if can_grow:
					h += 1
			for j in h:
				for i in w:
					visited[y + j][x + i] = true
			var shape := RectangleShape2D.new()
			shape.size = Vector2(w * TILE, h * TILE)
			var cs := CollisionShape2D.new()
			cs.shape = shape
			cs.position = Vector2(x * TILE + w * TILE / 2.0, y * TILE + h * TILE / 2.0)
			body.add_child(cs)


func _apply_initial_state() -> void:
	puzzle_done = Game.solved_rooms.has(room_id)
	for key in doors:
		for d in doors[key]:
			d.set_open(true, false)
	for g in gates:
		g.set_open(puzzle_done, false)
	match data["type"]:
		"puzzle":
			_update_locks(false)
		"combat":
			if Game.cleared_rooms.has(room_id):
				state = State.DONE
			else:
				state = State.WAITING
		_:
			state = State.DONE


func _place_player() -> void:
	if player == null:
		return
	var pos: Vector2 = spawns.get(spawn_key, spawns.get("a", Vector2(COLS * TILE / 2.0, ROWS * TILE / 2.0)))
	entry_pos = pos
	player.room = self
	player.global_position = pos
	player.last_safe_pos = pos
	entities.add_child(player)
	if data.has("hint") and data["hint"] != "":
		get_tree().create_timer(1.2).timeout.connect(func(): Game.show_message(data["hint"]))


# --- Puzzles y puertas ---------------------------------------------------------------------
func _update_locks(announce: bool) -> void:
	if data["type"] != "puzzle":
		return
	var req: String = data.get("requires_item", "")
	var unlocked := puzzle_done and (req == "" or Game.has_item(req))
	var any_locked := false
	for key in data.get("locked_exits", []):
		any_locked = true
		for d in doors.get(key, []):
			d.set_open(unlocked, announce)
	if announce and any_locked and unlocked and not _unlock_announced:
		_unlock_announced = true
		Game.show_message("La puerta se abrió.")


func _on_item_collected(_item_id: String) -> void:
	_update_locks(true)


func _solve_puzzle() -> void:
	puzzle_done = true
	Game.solved_rooms[room_id] = true
	for g in gates:
		g.set_open(true)
		var c := pos_to_cell(g.position)
		if c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS:
			grid[c.y][c.x] = "."   # la casilla de la compuerta pasa a ser transitable
	Game.show_message("¡Se abrió una compuerta!")
	_update_locks(true)


func _unsolve_puzzle() -> void:
	puzzle_done = false
	_unlock_announced = false
	Game.solved_rooms.erase(room_id)
	for g in gates:
		g.set_open(false)
		var c := pos_to_cell(g.position)
		if c.x >= 0 and c.y >= 0 and c.x < COLS and c.y < ROWS:
			grid[c.y][c.x] = "g"
	Game.show_message("La compuerta se cerró.")
	_update_locks(true)


func _on_door_entered(exit_key: String) -> void:
	if state == State.COMBAT:
		return
	var ex: Dictionary = data["exits"].get(exit_key, {})
	if ex.is_empty():
		return
	exit_requested.emit(ex["room"], ex["spawn"])


# --- Combate -------------------------------------------------------------------------------
func _start_combat() -> void:
	state = State.COMBAT
	for key in doors:
		for d in doors[key]:
			d.set_open(false)
	enemies_alive = enemy_spawns.size()
	for s in enemy_spawns:
		var e: Enemy = (SLIME_SCENE if s["kind"] == "m" else TIKI_SCENE).instantiate()
		e.position = cell_to_pos(s["cell"])
		e.setup(player)
		e.died.connect(_on_enemy_died)
		entities.add_child(e)
	if enemies_alive == 0:
		_clear_room()
	else:
		Game.show_message("¡Derrota a todos los enemigos!")


func _on_enemy_died(_enemy: Enemy) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and state == State.COMBAT:
		_clear_room()


func _clear_room() -> void:
	state = State.DONE
	Game.cleared_rooms[room_id] = true
	for key in doors:
		for d in doors[key]:
			d.set_open(true)
	Game.show_message("Sala despejada.")


# --- Bucle ---------------------------------------------------------------------------------
func _physics_process(_delta: float) -> void:
	if state == State.WAITING and player != null \
			and player.global_position.distance_to(entry_pos) > TILE * 2.75:
		_start_combat()
	if plates.size() > 0 or (not puzzle_done and switches.size() > 0):
		_check_puzzle()


func _check_puzzle() -> void:
	var all_ok := true
	var changed := false
	for p in plates:
		var b := block_at(p)
		var pressed := b != null and not b.busy
		if plates_pressed.get(p, false) != pressed:
			plates_pressed[p] = pressed
			if plate_sprites.has(p) and is_instance_valid(plate_sprites[p]):
				plate_sprites[p].modulate = Color(0.75, 0.9, 0.75) if pressed else Color.WHITE
			changed = true
		if not pressed:
			all_ok = false
	for b in blocks:
		if is_instance_valid(b):
			b.set_lit(not b.busy and b.cell in plates)
	for s in switches:
		if not s.active:
			all_ok = false
	if changed:
		queue_redraw()
	if all_ok and not puzzle_done:
		_solve_puzzle()
	elif not all_ok and puzzle_done:
		_unsolve_puzzle()


func _process(delta: float) -> void:
	if _has_lava:
		_lava_timer += delta
		if _lava_timer >= 0.5:
			_lava_timer = 0.0
			lava_frame = 1 - lava_frame
			queue_redraw()


func _draw() -> void:
	if _is_manual:
		return
	var tile_size := Vector2(TILE, TILE)
	var altars: Array[Vector2] = []
	for y in ROWS:
		for x in COLS:
			var ch: String = grid[y][x]
			var pos := Vector2(x * TILE, y * TILE)
			var dest := Rect2(pos, tile_size)
			if ch == "#":
				var below := char_at(Vector2i(x, y + 1))
				draw_texture_rect(TEX_WALL_FACE if below != "#" else TEX_WALL_TOP, dest, false)
			elif ch == "~":
				draw_texture_rect_region(TEX_LAVA, dest, Rect2(lava_frame * 16, 0, 16, 16))
			else:
				draw_texture_rect(TEX_FLOOR_B if (x * 7 + y * 13) % 5 == 0 else TEX_FLOOR_A, dest, false)
				match ch:
					"P":
						draw_texture_rect(TEX_PEDESTAL, dest, false)
					"A":
						altars.append(pos)
					"T":
						draw_texture_rect(TEX_PLATE, dest, false)
	for pos in altars:
		var altar_rect := Rect2(pos - Vector2(TILE * 0.5, TILE * 0.5), Vector2(TILE * 2, TILE * 2))
		draw_texture_rect(TEX_ALTAR, altar_rect, false)
