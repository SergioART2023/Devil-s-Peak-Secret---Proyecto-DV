extends Node
## Toma capturas de varias salas (requiere renderizado real, no --headless).
## xvfb-run -a godot --path . res://tests/screenshot.tscn -- --out=/ruta/

var out := "/tmp/"

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.get_slice("=", 1)
	_run.call_deferred()

func _run() -> void:
	Game.reset_run()
	Game.give_item("sword")
	Game.give_item("bow")
	var gs: Node = load("res://scenes/game.tscn").instantiate()
	get_tree().root.add_child(gs)
	for id in RoomData.ORDER:
		gs._load_room(id, "a")
		gs.player.global_position = gs.room.cell_to_pos(Vector2i(4, 7))
		gs.hud.set_fade(0.0)
		await get_tree().create_timer(1.6).timeout
		get_viewport().get_texture().get_image().save_png(out + "shot_%s.png" % id)
	get_tree().quit()
