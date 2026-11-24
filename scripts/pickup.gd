class_name Pickup
extends Area2D
## Objeto recogible: espada, arco, esmeralda o corazon.

const SCALES := {
	"sword": Vector2.ONE,
	"bow": Vector2.ONE,
	"emerald": Vector2(1.5, 1.5),
	"heart": Vector2(2.0, 2.0),
}

@export_enum("sword", "bow", "emerald", "heart") var item_id: String = "sword":
	set(val):
		item_id = val
		if is_node_ready():
			_apply_visual()
var key := ""

@onready var sprite: AnimatedSprite2D = $Sprite2D


func _ready() -> void:
	_apply_visual()
	if key == "":
		var room_name: String = str(owner.name) if owner != null else "room"
		key = "%s:%d,%d" % [room_name, int(position.x), int(position.y)]
	if Game.taken_items.has(key):
		queue_free()
		return
	body_entered.connect(_on_body_entered)
	var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(sprite, "position:y", -3.0, 0.7)
	tw.tween_property(sprite, "position:y", 0.0, 0.7)


func _apply_visual() -> void:
	if sprite == null:
		return
	sprite.scale = SCALES.get(item_id, Vector2(2.0, 2.0))
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(item_id):
		sprite.play(item_id)


func _on_body_entered(body: Node) -> void:
	if not body is Player:
		return
	if item_id == "heart":
		if Game.hp >= Game.MAX_HP:
			return
		Game.heal(2)
		Game.show_message("Recuperaste vida.")
	else:
		match item_id:
			"sword":
				Game.show_message("¡Obtuviste la espada! (J o Espacio para atacar)")
			"bow":
				Game.show_message("¡Obtuviste el arco! (K o X para disparar)")
		Game.give_item(item_id)
	Game.taken_items[key] = true
	set_deferred("monitoring", false)
	queue_free()
