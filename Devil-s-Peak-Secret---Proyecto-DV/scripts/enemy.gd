class_name Enemy
extends CharacterBody2D
## Clase base de enemigos: vida, dano por contacto, retroceso y muerte.
## Los enemigos concretos sobreescriben _ai(delta).

signal died(enemy: Enemy)

@export var max_hp := 2
@export var contact_damage := 1

var hp := 2
var player: Player
var knock := Vector2.ZERO
var knock_time := 0.0
var dead := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")


func setup(p: Player) -> void:
	player = p


func _physics_process(delta: float) -> void:
	if dead:
		return
	if knock_time > 0.0:
		knock_time -= delta
		velocity = knock
	else:
		_ai(delta)
	move_and_slide()
	_contact_check()


func _ai(_delta: float) -> void:
	velocity = Vector2.ZERO


func _contact_check() -> void:
	if contact_damage > 0 and player != null and player.state != Player.State.DEAD \
			and global_position.distance_to(player.global_position) < 11.0:
		player.take_damage(contact_damage, global_position)


func take_damage(amount: int, from_pos: Vector2) -> void:
	if dead:
		return
	hp -= amount
	knock = (global_position - from_pos).normalized() * 130.0
	knock_time = 0.18
	sprite.modulate = Color(1.0, 0.35, 0.35)
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	if hp <= 0:
		_die()


func _die() -> void:
	dead = true
	set_deferred("collision_layer", 0)
	died.emit(self)
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.5, 0.1), 0.25)
	tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.25)
	await tw.finished
	queue_free()
