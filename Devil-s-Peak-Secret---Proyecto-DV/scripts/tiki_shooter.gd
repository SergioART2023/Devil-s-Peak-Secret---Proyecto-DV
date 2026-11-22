class_name TikiShooter
extends Enemy
## Hombre con mascara tiki: se queda quieto, apunta al jugador y sopla dardos con su cerbatana.

const DART_SCENE := preload("res://scenes/projectiles/dart.tscn")
const RANGE := 440.0

var cooldown := 1.6
var busy := false
var row := 0


func _ai(delta: float) -> void:
	velocity = Vector2.ZERO
	if player == null or player.state == Player.State.DEAD:
		return
	var to_player := player.global_position - global_position
	if not busy:
		if absf(to_player.x) > absf(to_player.y):
			row = 3 if to_player.x > 0.0 else 2
		else:
			row = 0 if to_player.y > 0.0 else 1
		sprite.frame = row * 2
	cooldown -= delta
	if cooldown <= 0.0 and not busy and to_player.length() < RANGE:
		_shoot()


func _shoot() -> void:
	busy = true
	sprite.frame = row * 2 + 1          # animacion de "inflar mejillas" antes de disparar
	await get_tree().create_timer(0.45).timeout
	if dead or player == null:
		return
	var dart: Dart = DART_SCENE.instantiate()
	dart.direction = (player.global_position - global_position).normalized()
	get_parent().add_child(dart)
	dart.global_position = global_position + dart.direction * 16.0
	cooldown = 2.2
	await get_tree().create_timer(0.2).timeout
	busy = false
