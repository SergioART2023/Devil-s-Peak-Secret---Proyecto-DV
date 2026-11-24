class_name Hud
extends CanvasLayer
## Interfaz: corazones, objetos, mensajes, titulo de sala, fundidos y pantalla de derrota.
## Se construye por codigo para mantener la escena simple.

# --- DEV: poner en false para ocultar/quitar los botones de teletransporte entre salas ---
const DEV_ROOM_NAV := false
signal dev_room_requested(room_id: String)

const VIEW_W := Room.COLS * Room.TILE
const VIEW_H := Room.ROWS * Room.TILE
const HUD_MARGIN := 12
const ITEM_SLOT_W := 56
const HEARTS_TEX := preload("res://assets/sprites/ui/hearts.png")
const SWORD_TEX := preload("res://assets/sprites/items/sword.png")
const BOW_TEX := preload("res://assets/sprites/items/bow.png")

var hearts: HeartsRow
var items: ItemsRow
var fade: ColorRect
var msg_label: Label
var title_label: Label
var over_panel: Control
var help_button: Button
var help_panel: PanelContainer
var _msg_tween: Tween
var _title_tween: Tween


class HeartsRow extends Control:
	var hp := Game.MAX_HP
	var tex: Texture2D

	func _draw() -> void:
		for i in Game.MAX_HP / 2:
			var v := clampi(hp - i * 2, 0, 2)   # 0 vacio, 1 medio, 2 lleno
			draw_texture_rect_region(tex, Rect2(i * 34, 0, 32, 32), Rect2(v * 16, 0, 16, 16))


class ItemsRow extends Control:
	var sword_tex: Texture2D
	var bow_tex: Texture2D

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var x := size.x - ITEM_SLOT_W
		if Game.has_item("bow"):
			_draw_item(bow_tex, "K", x, font)
			x -= ITEM_SLOT_W
		if Game.has_item("sword"):
			_draw_item(sword_tex, "J", x, font)

	func _draw_item(texture: Texture2D, key: String, x: float, font: Font) -> void:
		draw_texture_rect(texture, Rect2(x, 0, 32, 32), false)
		var key_position := Vector2(x + 34, 26)
		draw_string_outline(font, key_position, key, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, Color.BLACK)
		draw_string(font, key_position, key, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)


func _ready() -> void:
	layer = 10

	hearts = HeartsRow.new()
	hearts.tex = HEARTS_TEX
	hearts.position = Vector2(HUD_MARGIN, HUD_MARGIN)
	hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hearts)

	items = ItemsRow.new()
	items.sword_tex = SWORD_TEX
	items.bow_tex = BOW_TEX
	items.position = Vector2(VIEW_W - HUD_MARGIN - 2 * ITEM_SLOT_W, HUD_MARGIN)
	items.size = Vector2(2 * ITEM_SLOT_W, 32)
	items.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(items)

	if DEV_ROOM_NAV:
		_build_dev_room_nav()

	msg_label = _make_label(Vector2(0, VIEW_H - 80), 20)
	msg_label.modulate.a = 0.0
	title_label = _make_label(Vector2(0, 200), 36)
	title_label.modulate.a = 0.0

	_build_help()
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


func _build_help() -> void:
	help_panel = PanelContainer.new()
	help_panel.position = Vector2(VIEW_W - 388, VIEW_H - 256)
	help_panel.size = Vector2(376, 0)
	help_panel.hide()
	add_child(help_panel)

	var controls := Label.new()
	controls.text = "Cómo jugar\n\nMoverse · WASD o flechas\nEspada · J o Espacio\nArco · K o X\nEmpujar o halar bloques · Mantén E\nReiniciar sala · R\nVolver al menú · Esc"
	controls.add_theme_font_size_override("font_size", 18)
	help_panel.add_child(controls)

	help_button = Button.new()
	help_button.text = "?"
	help_button.tooltip_text = "Cómo jugar"
	help_button.position = Vector2(VIEW_W - 56, VIEW_H - 56)
	help_button.size = Vector2(44, 44)
	help_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	help_button.add_theme_font_size_override("font_size", 25)
	var circle := StyleBoxFlat.new()
	circle.bg_color = Color(0.23, 0.10, 0.07)
	circle.border_color = Color(0.91, 0.63, 0.31)
	circle.set_border_width_all(2)
	circle.set_corner_radius_all(22)
	help_button.add_theme_stylebox_override("normal", circle)
	var highlighted := circle.duplicate() as StyleBoxFlat
	highlighted.bg_color = Color(0.40, 0.16, 0.08)
	help_button.add_theme_stylebox_override("hover", highlighted)
	help_button.add_theme_stylebox_override("pressed", highlighted)
	var focus := circle.duplicate() as StyleBoxFlat
	focus.draw_center = false
	focus.border_color = Color.WHITE
	help_button.add_theme_stylebox_override("focus", focus)
	help_button.pressed.connect(func() -> void: help_panel.visible = not help_panel.visible)
	add_child(help_button)


func close_help() -> void:
	help_panel.hide()


# --- DEV: botones de navegacion rapida entre salas (borrar junto con DEV_ROOM_NAV) ---
func _build_dev_room_nav() -> void:
	var row := HBoxContainer.new()
	row.position = Vector2(250, VIEW_H - 29)
	row.size = Vector2(460, 26)
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
	help_button.visible = not visible_flag
	if visible_flag:
		close_help()


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
