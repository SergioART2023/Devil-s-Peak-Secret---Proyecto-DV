class_name Arrow
extends Area2D
## Flecha del jugador: dana enemigos, activa interruptores y se detiene en paredes y bloques.

const SPEED := 220.0

var direction := Vector2.RIGHT
var life := 1.6


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body is Enemy:
		body.take_damage(1, global_position - direction * 8.0)
		queue_free()
	elif body is StaticBody2D:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area is ArrowSwitch:
		area.activate()
		queue_free()
