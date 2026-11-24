class_name Block
extends StaticBody2D
## Bloque de piedra que se empuja o se hala sobre la rejilla. Al caer en lava la tapa.

var room: Room
var cell := Vector2i.ZERO
var busy := false
var is_lit := false

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	_apply_lit()


func set_lit(value: bool) -> void:
	if is_lit == value:
		return
	is_lit = value
	if is_node_ready():
		_apply_lit()


func _apply_lit() -> void:
	if sprite != null:
		sprite.frame = 1 if is_lit else 0


func setup(r: Room, c: Vector2i) -> void:
	room = r
	cell = c
	position = r.cell_to_pos(c)


func try_push(dir: Vector2i) -> bool:
	if busy:
		return false
	var target := cell + dir
	if not room.can_block_enter(target):
		return false
	move_to(target, 0.22)
	return true


func move_to(target: Vector2i, duration: float = 0.22) -> void:
	busy = true
	set_lit(false)
	cell = target
	var tw := create_tween()
	tw.tween_property(self, "position", room.cell_to_pos(target), duration)
	await tw.finished
	busy = false
	if is_instance_valid(room) and room.is_lava(cell):
		room.fill_lava(cell, self)
		_sink()


func _sink() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	z_index = -1
	var tw := create_tween().set_parallel(true)
	tw.tween_property(sprite, "position:y", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "scale", Vector2(0.92, 0.78), 0.35).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "modulate", Color(0.95, 0.78, 0.70, 1.0), 0.35)


func set_sunken() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	z_index = -1
	if sprite != null:
		sprite.position.y = 1.0
		sprite.scale = Vector2(0.92, 0.78)
		sprite.modulate = Color(0.95, 0.78, 0.70, 1.0)
