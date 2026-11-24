class_name Hud
extends CanvasLayer
## Interfaz: corazones, objetos, mensajes, titulo de sala, fundidos y pantalla de derrota.
## Se construye por codigo para mantener la escena simple.

# --- DEV: poner en false para ocultar/quitar los botones de teletransporte entre salas ---
const DEV_ROOM_NAV := false
signal dev_room_requested(room_id: String)

const VIEW_W := 960
const VIEW_H := 544
const BAR_H := 32
const BAR_Y := 512
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
			draw_texture_rect_region(tex, Rect2(8 + i * 34, 0, 32, 32), Rect2(v * 16, 0, 16, 16))


class ItemsRow extends Control:
	var sword_tex: Texture2D
	var bow_tex: Texture2D

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var x := 0.0
		if Game.has_item("sword"):
			draw_texture_rect(sword_tex, Rect2(x, 0, 32, 32), false)
			draw_string(font, Vector2(x + 28, 26), "J", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.8))
			x += 68.0
		if Game.has_item("bow"):
			draw_texture_rect(bow_tex, Rect2(x, 0, 32, 32), false)
			draw_string(font, Vector2(x + 28, 26), "K", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.8))


func _ready() -> void:
	layer = 10
	# Barra inferior
	var bar := ColorRect.new()
	bar.color = Color(0.05, 0.03, 0.03)
	bar.position = Vector2(0, BAR_Y)
	bar.size = Vector2(VIEW_W, BAR_H)
	add_child(bar)

	hearts = HeartsRow.new()
	hearts.tex = HEARTS_TEX
	hearts.position = Vector2(0, BAR_Y)
	hearts.size = Vector2(240, BAR_H)
	add_child(hearts)

	items = ItemsRow.new()
	items.sword_tex = SWORD_TEX
	items.bow_tex = BOW_TEX
	items.position = Vector2(VIEW_W - 160, BAR_Y)
	items.size = Vector2(160, BAR_H)
	add_child(items)

	if DEV_ROOM_NAV:
		_build_dev_room_nav()

	msg_label = _make_label(Vector2(0, BAR_Y - 48), 20)
	msg_label.modulate.a = 0.0
	title_label = _make_label(Vector2(0, 200), 36)
	title_label.modulate.a = 0.0

	_build_game_over()

	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.size = Vector2(VIEW_W, VIEW_H)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

	Game.hp_changed.connect(_on_hp_changed)
	Game.inventory_changed.connect(items.queue_redraw)
	Game.message_requested.connect(show_message)
	_on_hp_changed(Game.hp, Game.MAX_HP)


# --- DEV: botones de navegacion rapida entre salas (borrar junto con DEV_ROOM_NAV) ---
func _build_dev_room_nav() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(250, BAR_Y + 3)
	row.size = Vector2(460, BAR_H - 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	add_child(row)

	for i in RoomData.ORDER.size():
		var rid: String = RoomData.ORDER[i]
		var btn := Button.new()
		btn.text = "R%d" % i
		btn.tooltip_text = "%s (%s)" % [rid, RoomData.ROOMS[rid]["name"]]
		btn.custom_minimum_size = Vector2(44, 24)
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(func() -> void: dev_room_requested.emit(rid))
		row.add_child(btn)

	var gear_btn := Button.new()
	gear_btn.text = "+Gear"
	gear_btn.tooltip_text = "Equipar espada y arco (DEV)"
	gear_btn.custom_minimum_size = Vector2(56, 24)
	gear_btn.focus_mode = Control.FOCUS_NONE
	gear_btn.add_theme_font_size_override("font_size", 12)
	gear_btn.pressed.connect(func() -> void:
		Game.give_item("sword")
		Game.give_item("bow")
		Game.show_message("DEV: Espada y arco equipados.", 1.5)
	)
	row.add_child(gear_btn)


func _make_label(pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = Vector2(VIEW_W, 48)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l


func _build_game_over() -> void:
	over_panel = Control.new()
	over_panel.visible = false
	add_child(over_panel)
	var bg := ColorRect.new()
	bg.color = Color(0.25, 0.0, 0.0, 0.75)
	bg.size = Vector2(VIEW_W, VIEW_H)
	over_panel.add_child(bg)
	var t := Label.new()
	t.text = "HAS CAÍDO EN EL TEMPLO"
	t.position = Vector2(0, 200)
	t.size = Vector2(VIEW_W, 60)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 44)
	over_panel.add_child(t)
	var s := Label.new()
	s.text = "Presiona ENTER para reintentar la sala"
	s.position = Vector2(0, 272)
	s.size = Vector2(VIEW_W, 40)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.add_theme_font_size_override("font_size", 24)
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
