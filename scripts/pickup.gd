class_name Pickup
extends Area2D
## Objeto recogible: espada, arco, esmeralda o corazon.

const TEXTURES := {
	"sword": preload("res://assets/sprites/items/sword.png"),
	"bow": preload("res://assets/sprites/items/bow.png"),
	"emerald": preload("res://assets/sprites/items/emerald.png"),
	"heart": preload("res://assets/sprites/items/heart.png"),
}

var item_id := ""
var key := ""

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.texture = TEXTURES[item_id]
	body_entered.connect(_on_body_entered)
	# Flotar suavemente
	var tw := create_tween().set_loops()
	tw.tween_property(sprite, "position:y", -3.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE)


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
