class_name VolcanicBoulder
extends Area2D
## Bola de piedra volcanica en fuego que rueda hacia abajo desde una compuerta norte.

@export var speed := 175.0
@export var damage := 1
@export var max_y := 472.0

var _shattering := false

@onready var sprite: AnimatedSprite2D = $Sprite2D


func _ready() -> void:
	if sprite != null:
		sprite.play("roll")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _shattering:
		return
	position.y += speed * delta
	if position.y >= max_y:
		_shatter()


func _on_body_entered(body: Node) -> void:
	if _shattering:
		return
	if body is Player:
		body.take_damage(damage, global_position)
		_shatter()
	elif body is StaticBody2D and not body is Door:
		_shatter()


func _shatter() -> void:
	if _shattering:
		return
	_shattering = true
	set_deferred("monitoring", false)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.35, 1.35), 0.14)
	tw.tween_property(self, "modulate:a", 0.0, 0.14)
	await tw.finished
	queue_free()
