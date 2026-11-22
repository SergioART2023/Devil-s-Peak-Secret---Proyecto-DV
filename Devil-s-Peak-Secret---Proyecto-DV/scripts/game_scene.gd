extends Node2D
## Escena principal de juego: carga salas, mueve al jugador entre ellas y gestiona
## la secuencia de la caida, la derrota y el final.

const PLAYER_SCENE := preload("res://scenes/player.tscn")

@onready var room_holder: Node2D = $RoomHolder
@onready var hud: Hud = $HUD

var room: Room
var player: Player
var current_room_id := ""
var current_spawn := "a"
var transitioning := false
var game_over := false


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	player.died.connect(_on_player_died)
	Game.item_collected.connect(_on_item_collected)
	hud.set_fade(1.0)
	_load_room(Game.start_room, Game.start_spawn)
	hud.fade_in(0.6)


func _load_room(id: String, spawn: String) -> void:
	if room != null:
		if player.get_parent() != null:
			player.get_parent().remove_child(player)
		room_holder.remove_child(room)
		room.queue_free()
	current_room_id = id
	current_spawn = spawn
	room = Room.new()
	room.room_id = id
	room.spawn_key = spawn
	room.player = player
	room.exit_requested.connect(_on_exit_requested)
	room_holder.add_child(room)
	player.reset_for_room()
	hud.show_room_title(RoomData.ROOMS[id]["name"])


func _on_exit_requested(target: String, spawn: String) -> void:
	if transitioning or game_over:
		return
	transitioning = true
	player.state = Player.State.LOCKED
	await hud.fade_out(0.25)
	if target == "@ending":
		Game.ending_kind = "hidden"
		Game.change_scene(Game.SCENE_ENDING)
		return
	if target == "@demo_end":
		Game.ending_kind = "demo"
		Game.change_scene(Game.SCENE_ENDING)
		return
	_load_room(target, spawn)
	await hud.fade_in(0.25)
	player.state = Player.State.NORMAL
	transitioning = false


func _on_item_collected(item_id: String) -> void:
	if item_id == "emerald" and current_room_id == "temple":
		_fall_sequence()


## Jacob toma la esmeralda: el templo tiembla, el suelo se abre y cae al cuarto oscuro.
func _fall_sequence() -> void:
	transitioning = true
	player.state = Player.State.LOCKED
	var tw := create_tween()
	for i in 14:
		tw.tween_property(room_holder, "position",
				Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0)), 0.05)
	tw.tween_property(room_holder, "position", Vector2.ZERO, 0.05)
	Game.show_message("¡El templo tiembla! ¡El suelo se abre!", 2.0)
	await tw.finished
	await hud.fade_out(0.9)
	_load_room("room_01", "a")
	player.state = Player.State.LOCKED
	await get_tree().create_timer(0.7).timeout
	Game.show_message("Jacob despierta en un cuarto oscuro...", 3.0)
	await hud.fade_in(0.9)
	player.state = Player.State.NORMAL
	transitioning = false


func _on_player_died() -> void:
	game_over = true
	hud.show_game_over(true)


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event.is_action_pressed("ui_accept"):
		game_over = false
		hud.show_game_over(false)
		Game.hp = Game.MAX_HP
		Game.hp_changed.emit(Game.hp, Game.MAX_HP)
		_load_room(current_room_id, current_spawn)
	elif event.is_action_pressed("restart_room") and not transitioning and not game_over:
		_load_room(current_room_id, current_spawn)   # util si un bloque queda atascado
	elif event.is_action_pressed("pause"):
		Game.change_scene(Game.SCENE_MENU)
