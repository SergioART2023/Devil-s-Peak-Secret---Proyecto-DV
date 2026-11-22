class_name ArrowSwitch
extends Area2D
## Interruptor que solo se activa con una flecha del arco.

signal activated

var active := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.frame = 1 if active else 0


func activate() -> void:
	if active:
		return
	active = true
	sprite.frame = 1
	activated.emit()
	Game.show_message("¡Interruptor activado!")
