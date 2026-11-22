extends Control
## Pantalla final. Dos variantes segun Game.ending_kind:
##  - "hidden": final oculto (Jacob no toma la esmeralda). Reproduce un video si existe en
##    res://assets/video/final_oculto.ogv (formato Ogg Theora); si no, muestra un texto provisional.
##  - "demo": fin de la primera entrega.

const VIDEO_PATH := "res://assets/video/final_oculto.ogv"

var _can_exit := false


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	if Game.ending_kind == "hidden" and ResourceLoader.exists(VIDEO_PATH):
		var video := VideoStreamPlayer.new()
		video.stream = load(VIDEO_PATH)
		video.set_anchors_preset(Control.PRESET_FULL_RECT)
		video.expand = true
		video.finished.connect(_show_credits)
		add_child(video)
		video.play()
		_can_exit = true   # permite saltar el video con ENTER
		return
	_show_credits()


func _show_credits() -> void:
	for c in get_children():
		if c is VideoStreamPlayer:
			c.queue_free()
	var text := ""
	if Game.ending_kind == "hidden":
		text = "FINAL OCULTO\n\nJacob renunció a la esmeralda y dejó el volcán.\nVolvió a casa en lancha con relojes antiguos,\ncuarzos y pepitas de oro.\n\n(Aquí irá el video generado: assets/video/final_oculto.ogv)"
	else:
		text = "FIN DE LA PRIMERA ENTREGA\n\nJacob aún tiene mucho templo por explorar...\n\nPróximamente: más salas, jefe final y música."
	var l := Label.new()
	l.text = text + "\n\n\nDEVIL'S PEAK SECRET\nJonathan Aristizabal Vargas · Sergio Rodriguez Trujillo\nUniversidad del Valle\n\nENTER: volver al menú"
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 12)
	add_child(l)
	_can_exit = true


func _unhandled_input(event: InputEvent) -> void:
	if _can_exit and event.is_action_pressed("ui_accept"):
		Game.change_scene(Game.SCENE_MENU)
