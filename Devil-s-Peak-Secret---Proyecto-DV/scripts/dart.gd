class_name Dart
extends Area2D
## Dardo de cerbatana lanzado por los enemigos tiki.

const SPEED := 95.0

var direction := Vector2.LEFT
var life := 3.0


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(1, global_position - direction * 8.0)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
