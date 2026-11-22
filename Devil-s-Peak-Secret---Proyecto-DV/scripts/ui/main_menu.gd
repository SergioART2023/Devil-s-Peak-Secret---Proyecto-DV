extends Control
## Menu principal.


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.03, 0.03)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_label("DEVIL'S PEAK SECRET", 60, 80, Color(1.0, 0.55, 0.2))
	_label("Universidad del Valle · Desarrollo de Videojuegos", 20, 160, Color(0.8, 0.7, 0.65))

	var start := _button("Iniciar aventura", 224)
	start.pressed.connect(_on_start)
	var quit := _button("Salir", 292)
	quit.pressed.connect(func(): get_tree().quit())
	start.grab_focus()

	_label("WASD / Flechas: mover   ·   J / Espacio: espada   ·   K / X: arco", 18, 392, Color(0.85, 0.8, 0.75))
	_label("E (mantener): agarrar bloque, empujar y halar   ·   R: reiniciar sala   ·   Esc: menú", 18, 420, Color(0.85, 0.8, 0.75))
	_label("Jonathan Aristizabal Vargas & Sergio Rodriguez Trujillo", 18, 500, Color(0.6, 0.5, 0.45))


func _label(text: String, size: int, y: float, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2(0, y)
	l.size = Vector2(960, 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l


func _button(text: String, y: float) -> Button:
	var b := Button.new()
	b.text = text
	b.position = Vector2(320, y)
	b.size = Vector2(320, 56)
	b.add_theme_font_size_override("font_size", 26)
	add_child(b)
	return b


func _on_start() -> void:
	Game.reset_run()
	Game.change_scene(Game.SCENE_GAME)
