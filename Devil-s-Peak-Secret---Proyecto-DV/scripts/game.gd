extends Node
## Estado global de la partida (autoload "Game").
## Guarda vida, inventario y el progreso de las salas; tambien registra las acciones de entrada.

signal hp_changed(hp: int, max_hp: int)
signal inventory_changed
signal message_requested(text: String, seconds: float)
signal item_collected(item_id: String)

const MAX_HP := 6   # 3 corazones (cada corazon = 2 puntos)
const SCENE_MENU := "res://scenes/ui/main_menu.tscn"
const SCENE_GAME := "res://scenes/game.tscn"
const SCENE_ENDING := "res://scenes/ui/ending.tscn"

var hp: int = MAX_HP
var inventory: Dictionary = {"sword": false, "bow": false, "emerald": false}
var cleared_rooms: Dictionary = {}   # salas de combate ya superadas
var solved_rooms: Dictionary = {}    # salas de puzzle ya resueltas
var taken_items: Dictionary = {}     # objetos ya recogidos ("sala:col,fila")
var start_room: String = "temple"
var start_spawn: String = "a"
var ending_kind: String = "hidden"   # "hidden" (final oculto) | "demo" (fin de la primera entrega)
var debug_room: String = ""          # se llena con:  godot --path . -- --room=room_03


func _ready() -> void:
	_setup_input()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--room="):
			debug_room = arg.get_slice("=", 1)


func reset_run() -> void:
	hp = MAX_HP
	inventory = {"sword": false, "bow": false, "emerald": false}
	cleared_rooms.clear()
	solved_rooms.clear()
	taken_items.clear()
	start_room = "temple"
	start_spawn = "a"
	if debug_room != "" and RoomData.ROOMS.has(debug_room):
		# Atajo para probar una sala concreta con el equipo que tendria el jugador ahi.
		start_room = debug_room
		var idx: int = RoomData.ORDER.find(debug_room)
		inventory["sword"] = idx >= 2
		inventory["bow"] = idx >= 4
	hp_changed.emit(hp, MAX_HP)
	inventory_changed.emit()


func has_item(id: String) -> bool:
	return inventory.get(id, false)


func give_item(id: String) -> void:
	inventory[id] = true
	inventory_changed.emit()
	item_collected.emit(id)


func damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, MAX_HP)


func heal(amount: int) -> void:
	hp = mini(hp + amount, MAX_HP)
	hp_changed.emit(hp, MAX_HP)


func show_message(text: String, seconds: float = 3.0) -> void:
	message_requested.emit(text, seconds)


func change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


# --- Entrada -------------------------------------------------------------------------------
func _setup_input() -> void:
	_add_action("move_left", [KEY_A, KEY_LEFT])
	_add_action("move_right", [KEY_D, KEY_RIGHT])
	_add_action("move_up", [KEY_W, KEY_UP])
	_add_action("move_down", [KEY_S, KEY_DOWN])
	_add_action("attack", [KEY_J, KEY_SPACE])      # espada
	_add_action("bow", [KEY_K, KEY_X])             # arco
	_add_action("grab", [KEY_E, KEY_SHIFT])        # agarrar bloques (empujar / halar)
	_add_action("restart_room", [KEY_R])
	_add_action("pause", [KEY_ESCAPE])


func _add_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
