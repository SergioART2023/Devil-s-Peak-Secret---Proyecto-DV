class_name FireSlime
extends Enemy
## Slime de fuego: deambula y, si ve al jugador, se acerca para atacar.

const SPEED := 34.0
const SIGHT := 120.0

var wander_dir := Vector2.ZERO
var wander_time := 0.0
var anim_time := 0.0


func _ai(delta: float) -> void:
	anim_time += delta
	sprite.frame = int(anim_time * 4.0) % 2
	if player != null and player.state != Player.State.DEAD \
			and global_position.distance_to(player.global_position) < SIGHT:
		velocity = (player.global_position - global_position).normalized() * SPEED
		return
	wander_time -= delta
	if wander_time <= 0.0:
		wander_time = randf_range(0.8, 1.8)
		wander_dir = Vector2.from_angle(randf() * TAU) if randf() > 0.35 else Vector2.ZERO
	velocity = wander_dir * (SPEED * 0.5)
