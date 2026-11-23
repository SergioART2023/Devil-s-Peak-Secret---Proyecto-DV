class_name Door
extends StaticBody2D
## Puerta de salida (kind = "door") o compuerta de puzzle (kind = "gate").

signal entered(exit_key: String)

@export_enum("door", "gate") var kind := "door"
@export var exit_key := ""
var is_open := false

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var trigger: Area2D = $Trigger


func _ready() -> void:
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(&"open"):
		sprite.sprite_frames.set_animation_loop(&"open", false)
	if kind == "gate":
		trigger.monitoring = false
	else:
		trigger.body_entered.connect(_on_trigger_body_entered)
	_apply(false)


func set_open(value: bool, animate: bool = true) -> void:
	var changed := is_open != value
	is_open = value
	if is_node_ready():
		_apply(animate and changed)


func _apply(animate: bool = true) -> void:
	shape.set_deferred("disabled", is_open)
	if kind != "gate":
		trigger.set_deferred("monitoring", is_open)

	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"open"):
		return
	var last_frame := maxi(sprite.sprite_frames.get_frame_count(&"open") - 1, 0)
	if animate:
		if is_open:
			sprite.play(&"open")
		else:
			sprite.play_backwards(&"open")
	else:
		sprite.stop()
		sprite.animation = &"open"
		sprite.frame = last_frame if is_open else 0


func _on_trigger_body_entered(body: Node) -> void:
	if is_open and body is Player:
		entered.emit(exit_key)
