class_name Hud
extends CanvasLayer
## Interfaz: corazones, objetos, mensajes, titulo de sala, fundidos y pantalla de derrota.
## Se construye por codigo para mantener la escena simple.

const BAR_Y := 256
const HEARTS_TEX := preload("res://assets/sprites/ui/hearts.png")
const SWORD_TEX := preload("res://assets/sprites/items/sword.png")
const BOW_TEX := preload("res://assets/sprites/items/bow.png")

var hearts: HeartsRow
var items: ItemsRow
var fade: ColorRect
var msg_label: Label
var title_label: Label
var over_panel: Control
var _msg_tween: Tween
var _title_tween: Tween


class HeartsRow extends Control:
	var hp := Game.MAX_HP
	var tex: Texture2D

	func _draw() -> void:
		for i in Game.MAX_HP / 2:
			var v := clampi(hp - i * 2, 0, 2)   # 0 vacio, 1 medio, 2 lleno
			draw_texture_rect_region(tex, Rect2(4 + i * 17, 0, 16, 16), Rect2(v * 16, 0, 16, 16))


class ItemsRow extends Control:
	var sword_tex: Texture2D
	var bow_tex: Texture2D

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var x := 0.0
		if Game.has_item("sword"):
			draw_texture(sword_tex, Vector2(x, 0))
			draw_string(font, Vector2(x + 14, 14), "J", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.8))
			x += 34.0
		if Game.has_item("bow"):
			draw_texture(bow_tex, Vector2(x, 0))
			draw_string(font, Vector2(x + 14, 14), "K", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1, 0.8))


func _ready() -> void:
	layer = 10
	# Barra inferior
	var bar := ColorRect.new()
	bar.color = Color(0.05, 0.03, 0.03)
	bar.position = Vector2(0, BAR_Y)
	bar.size = Vector2(480, 16)
	add_child(bar)

	hearts = HeartsRow.new()
	hearts.tex = HEARTS_TEX
	hearts.position = Vector2(0, BAR_Y)
	hearts.size = Vector2(120, 16)
	add_child(hearts)

	items = ItemsRow.new()
	items.sword_tex = SWORD_TEX
	items.bow_tex = BOW_TEX
	items.position = Vector2(400, BAR_Y)
	items.size = Vector2(80, 16)
	add_child(items)

	msg_label = _make_label(Vector2(0, 232), 10)
	msg_label.modulate.a = 0.0
	title_label = _make_label(Vector2(0, 100), 18)
	title_label.modulate.a = 0.0

	_build_game_over()

	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = Vector2(480, 272)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

	Game.hp_changed.connect(_on_hp_changed)
	Game.inventory_changed.connect(items.queue_redraw)
	Game.message_requested.connect(show_message)
	_on_hp_changed(Game.hp, Game.MAX_HP)


func _make_label(pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(480, 24)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)
	add_child(l)
	return l


func _build_game_over() -> void:
	over_panel = Control.new()
	over_panel.visible = false
	add_child(over_panel)
	var bg := ColorRect.new()
	bg.color = Color(0.25, 0.0, 0.0, 0.75)
	bg.size = Vector2(480, 272)
	over_panel.add_child(bg)
	var t := Label.new()
	t.text = "HAS CAÍDO EN EL TEMPLO"
	t.position = Vector2(0, 100)
	t.size = Vector2(480, 30)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 22)
	over_panel.add_child(t)
	var s := Label.new()
	s.text = "Presiona ENTER para reintentar la sala"
	s.position = Vector2(0, 136)
	s.size = Vector2(480, 20)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 12)
	over_panel.add_child(s)


func _on_hp_changed(hp: int, _max_hp: int) -> void:
	hearts.hp = hp
	hearts.queue_redraw()


func show_message(text: String, seconds: float = 3.0) -> void:
	if _msg_tween:
		_msg_tween.kill()
	msg_label.text = text
	msg_label.modulate.a = 1.0
	_msg_tween = create_tween()
	_msg_tween.tween_interval(seconds)
	_msg_tween.tween_property(msg_label, "modulate:a", 0.0, 0.5)


func show_room_title(text: String) -> void:
	if _title_tween:
		_title_tween.kill()
	title_label.text = text
	title_label.modulate.a = 0.0
	_title_tween = create_tween()
	_title_tween.tween_property(title_label, "modulate:a", 1.0, 0.4)
	_title_tween.tween_interval(1.4)
	_title_tween.tween_property(title_label, "modulate:a", 0.0, 0.6)


func show_game_over(visible_flag: bool) -> void:
	over_panel.visible = visible_flag


func set_fade(alpha: float) -> void:
	fade.color.a = alpha


func fade_out(seconds: float = 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, seconds)
	await tw.finished


func fade_in(seconds: float = 0.3) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, seconds)
	await tw.finished
