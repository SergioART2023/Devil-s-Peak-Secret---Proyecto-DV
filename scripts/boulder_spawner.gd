class_name BoulderSpawner
extends Node2D
## Compuerta en la pared norte que telegrafia con fuego y lanza bolas volcanicas hacia abajo.

const BOULDER_SCENE := preload("res://scenes/projectiles/volcanic_boulder.tscn")

@export var interval := 3.2
@export var initial_delay := 1.0
@export var telegraph_time := 0.55
@export var boulder_speed := 175.0
@export var stop_on_clear := true

var _timer := 0.0
var _telegraphing := false

@onready var sprite: Sprite2D = $Sprite2D
@onready var warn_light: PointLight2D = get_node_or_null("WarnLight")


func _ready() -> void:
	_timer = initial_delay
	_set_warning(false)


func _physics_process(delta: float) -> void:
	if stop_on_clear and _is_room_cleared():
		if _telegraphing:
			_telegraphing = false
			_set_warning(false)
		return
	_timer -= delta
	if not _telegraphing and _timer <= telegraph_time:
		_telegraphing = true
		_set_warning(true)
	if _timer <= 0.0:
		_telegraphing = false
		_set_warning(false)
		_spawn_boulder()
		_timer = interval


func _set_warning(on: bool) -> void:
	if sprite != null:
		sprite.frame = 1 if on else 0
	if warn_light != null:
		warn_light.visible = on


func _spawn_boulder() -> void:
	var b: VolcanicBoulder = BOULDER_SCENE.instantiate()
	b.speed = boulder_speed
	b.global_position = global_position + Vector2(0.0, 32.0)
	var parent_node: Node = get_parent().get_parent() if get_parent() != null and get_parent().get_parent() != null else get_tree().current_scene
	if parent_node.has_node("Entities"):
		parent_node.get_node("Entities").add_child(b)
	else:
		parent_node.add_child(b)


func _is_room_cleared() -> bool:
	var n: Node = get_parent()
	while n != null:
		if n is Room:
			return n.state == Room.State.DONE
		n = n.get_parent()
	return false
