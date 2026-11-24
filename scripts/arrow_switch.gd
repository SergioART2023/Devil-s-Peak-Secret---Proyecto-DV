class_name ArrowSwitch
extends Area2D
## Interruptor que solo se activa con una flecha del arco.

signal activated

@export var move_axis := Vector2.DOWN
@export var move_distance := 0.0
@export var move_speed := 2.0
@export var start_phase := 0.0

var active := false:
	set(val):
		active = val
		if is_node_ready() and sprite != null:
			sprite.frame = 1 if active else 0

var _origin := Vector2.ZERO
var _clock := 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_origin = position
	sprite.frame = 1 if active else 0


func _physics_process(delta: float) -> void:
	if move_distance > 0.0:
		_clock += delta * move_speed
		position = _origin + move_axis.normalized() * sin(_clock + start_phase) * move_distance


func activate() -> void:
	if active:
		return
	active = true
	sprite.frame = 1
	activated.emit()
	Game.show_message("¡Interruptor activado!")
