class_name Block
extends StaticBody2D
## Bloque de piedra que se empuja o se hala sobre la rejilla. Al caer en lava la tapa.

var room: Room
var cell := Vector2i.ZERO
var busy := false


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
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ZERO, 0.3)
	await tw.finished
	queue_free()
