class_name FireSlime
extends Enemy
## Blob de lava (sin ojos): deambula y, si ve al jugador, se acerca para atacar.
## Hoja fire_slime.png: 12 columnas x 2 filas de 32x32. Fila 0 = idle (12 frames), fila 1 = muerte (12).

const SPEED := 34.0
const SIGHT := 120.0
const COLUMNS := 12
const IDLE_FPS := 6.0
const MOVE_FPS := 10.0
const DEATH_FPS := 12.0

var wander_dir := Vector2.ZERO
var wander_time := 0.0
var anim_time := 0.0


func _ai(delta: float) -> void:
	var chasing := player != null and player.state != Player.State.DEAD \
			and global_position.distance_to(player.global_position) < SIGHT
	if chasing:
		velocity = (player.global_position - global_position).normalized() * SPEED
	else:
		wander_time -= delta
		if wander_time <= 0.0:
			wander_time = randf_range(0.8, 1.8)
			wander_dir = Vector2.from_angle(randf() * TAU) if randf() > 0.35 else Vector2.ZERO
		velocity = wander_dir * (SPEED * 0.5)
	anim_time += delta * (MOVE_FPS if velocity != Vector2.ZERO else IDLE_FPS)
	sprite.frame = int(anim_time) % COLUMNS


func _death_animation() -> void:
	for i in COLUMNS:
		sprite.frame = COLUMNS + i      # fila 1 de la hoja
		await get_tree().create_timer(1.0 / DEATH_FPS).timeout
	var tw := create_tween()
	tw.tween_property(sprite, "modulate:a", 0.0, 0.4)
	await tw.finished
