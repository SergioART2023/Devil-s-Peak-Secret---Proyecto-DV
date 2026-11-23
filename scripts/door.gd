class_name Door
extends StaticBody2D
## Puerta de salida (kind = "door") o compuerta de puzzle (kind = "gate").

signal entered(exit_key: String)

const GATE_TEX := preload("res://assets/sprites/tiles/gate.png")

var kind := "door"
var exit_key := ""
var is_open := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var trigger: Area2D = $Trigger


func _ready() -> void:
	if kind == "gate":
		sprite.texture = GATE_TEX
		sprite.hframes = 1
		trigger.monitoring = false
	else:
		trigger.body_entered.connect(_on_trigger_body_entered)
	_apply()


func set_open(value: bool) -> void:
	is_open = value
	if is_node_ready():
		_apply()


func _apply() -> void:
	shape.set_deferred("disabled", is_open)
	if kind == "gate":
		sprite.visible = not is_open
	else:
		sprite.frame = 1 if is_open else 0
		trigger.set_deferred("monitoring", is_open)


func _on_trigger_body_entered(body: Node) -> void:
	if is_open and body is Player:
		entered.emit(exit_key)
