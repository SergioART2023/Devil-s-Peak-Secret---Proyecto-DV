extends Control

@onready var background: TextureRect = $Background


func _ready() -> void:
	resized.connect(_fit_background)
	_fit_background()
	$Background/StartButton.grab_focus()


func _fit_background() -> void:
	var fit_scale := minf(size.x / background.size.x, size.y / background.size.y)
	background.scale = Vector2.ONE * fit_scale
	background.position = (size - background.size * fit_scale) * 0.5


func _on_start() -> void:
	Game.reset_run()
	Game.change_scene(Game.SCENE_GAME)


func _on_leave() -> void:
	get_tree().quit()
