class_name Player
extends CharacterBody2D
## Jacob, el protagonista: movimiento, espada, arco, empujar/halar bloques y dano.

signal died

enum State { NORMAL, ATTACK, SHOOT, PULL, DEAD, LOCKED }

const SPEED := 144.0
const SWORD_TIME := 0.24
const BOW_TIME := 0.25
const BOW_COOLDOWN := 0.5
const PUSH_DELAY := 0.22        # tiempo empujando contra un bloque antes de que se mueva
const GRAB_MOVE_TIME := 0.28    # duracion de un paso al empujar/halar con E
const INVULN_TIME := 1.0
const ARROW_SCENE := preload("res://scenes/projectiles/arrow.tscn")

const ANIM_IDLE := {
	Vector2i.DOWN: &"iso_idle_down_right",
	Vector2i.UP: &"iso_idle_up_right",
	Vector2i.LEFT: &"Idle Left_right",
	Vector2i.RIGHT: &"iso_idle_right_right",
}
const ANIM_WALK := {
	Vector2i.DOWN: &"iso_walk_down_right",
	Vector2i.UP: &"iso_walk_up_right",
	Vector2i.LEFT: &"Walk Left_right",
	Vector2i.RIGHT: &"iso_walk_right_right",
}
const ANIM_ATTACK := {
	Vector2i.DOWN: &"Attack Down_right",
	Vector2i.UP: &"Attack Up_right",
	Vector2i.LEFT: &"Attack Left_right",
	Vector2i.RIGHT: &"Attack Right_right",
}
const ANIM_SHOOT := {
	Vector2i.DOWN: &"Bow_Attack_Down",
	Vector2i.UP: &"Bow_Attack_Up",
	Vector2i.LEFT: &"Bow_Attack_Left",
	Vector2i.RIGHT: &"Bow_Attack_Right",
}

@export var attack_scale_mult := 1.34
@export var attack_offset := Vector2.ZERO
@export var bow_scale_mult := 1.0

@onready var sprite: AnimatedSprite2D = _find_animated_sprite()
@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var sword_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var back_sword: Sprite2D = get_node_or_null("BackSword")
@onready var back_bow: Sprite2D = get_node_or_null("BackBow")

var room: Room
var facing := Vector2i.DOWN
var state: State = State.NORMAL
var invuln := 0.0
var push_time := 0.0
var knock := Vector2.ZERO
var knock_time := 0.0
var walk_clock := 0.0
var bow_cd := 0.0
var safe_timer := 0.0
var last_safe_pos := Vector2.ZERO
var _sword_hit: Dictionary = {}
var _base_sprite_scale := Vector2.ONE
var _base_sprite_offset := Vector2.ZERO


func _ready() -> void:
	sword_shape.disabled = true
	sword_hitbox.body_entered.connect(_on_sword_body_entered)
	if sprite != null:
		_base_sprite_scale = sprite.scale
		_base_sprite_offset = sprite.offset


## Se llama cada vez que el jugador entra a una sala nueva.
func reset_for_room() -> void:
	state = State.NORMAL
	velocity = Vector2.ZERO
	knock_time = 0.0
	push_time = 0.0
	sprite.modulate = Color.WHITE
	invuln = 0.5


func _physics_process(delta: float) -> void:
	if invuln > 0.0:
		invuln -= delta
		sprite.modulate.a = 0.4 if int(invuln * 16.0) % 2 == 0 else 1.0
		if invuln <= 0.0:
			sprite.modulate.a = 1.0
	bow_cd = maxf(bow_cd - delta, 0.0)

	match state:
		State.NORMAL:
			_process_normal(delta)
		State.PULL:
			walk_clock += delta
		_:
			velocity = Vector2.ZERO
	_update_sprite()


func _process_normal(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if knock_time > 0.0:
		knock_time -= delta
		velocity = knock
		move_and_slide()
		return

	if Input.is_action_pressed("grab") and _grab(input):
		velocity = Vector2.ZERO
		return

	if Input.is_action_just_pressed("attack") and Game.has_item("sword"):
		_attack()
		return
	if Input.is_action_just_pressed("bow") and Game.has_item("bow") and bow_cd <= 0.0:
		_shoot()
		return

	if input != Vector2.ZERO:
		if absf(input.x) > absf(input.y):
			facing = Vector2i(1 if input.x > 0.0 else -1, 0)
		else:
			facing = Vector2i(0, 1 if input.y > 0.0 else -1)
		walk_clock += delta

	velocity = input * SPEED
	move_and_slide()
	_check_push(input, delta)

	if room != null:
		if room.is_lava(room.pos_to_cell(global_position + Vector2(0, 6))):
			_burn()
		else:
			_track_safe(delta)


# --- Empujar / halar -------------------------------------------------------------------------
## Empuje "natural": caminar contra un bloque durante un instante lo mueve una casilla.
func _check_push(input: Vector2, delta: float) -> void:
	var pushing := false
	if input != Vector2.ZERO:
		for i in get_slide_collision_count():
			var c := get_slide_collision(i)
			var b := c.get_collider() as Block
			if b == null:
				continue
			var n := -c.get_normal()
			var dir := Vector2i.ZERO
			if absf(n.x) > 0.9:
				dir = Vector2i(1 if n.x > 0.0 else -1, 0)
			elif absf(n.y) > 0.9:
				dir = Vector2i(0, 1 if n.y > 0.0 else -1)
			else:
				continue
			if input.dot(Vector2(dir)) > 0.6:
				pushing = true
				push_time += delta
				if push_time >= PUSH_DELAY:
					push_time = 0.0
					b.try_push(dir)
				break
	if not pushing:
		push_time = 0.0


## Agarrar (tecla E): con un bloque adelante, avanzar lo empuja y retroceder lo hala.
## Devuelve true si el jugador esta sujetando un bloque (no se mueve libremente).
func _grab(input: Vector2) -> bool:
	if room == null:
		return false
	var cell := room.pos_to_cell(global_position)
	var target := cell + facing
	var block := room.block_at(target)
	if block == null:
		return false
	if block.busy:
		return true
	var off := global_position - room.cell_to_pos(cell)
	var perp := absf(off.x) if facing.y != 0 else absf(off.y)
	if perp > 12.0:
		return false
	var f := Vector2(facing)
	var dir := Vector2i.ZERO
	if input.dot(f) > 0.7:
		dir = facing
	elif input.dot(f) < -0.7:
		dir = -facing
	else:
		return true
	var player_dest := cell + dir
	var block_dest: Vector2i
	if dir == facing:   # empujar
		block_dest = target + dir
		if not room.can_block_enter(block_dest, true):
			return true
	else:               # halar
		block_dest = cell
		if not room.is_cell_walkable(player_dest):
			return true
	_start_grab_move(block, block_dest, player_dest)
	return true


func _start_grab_move(block: Block, block_dest: Vector2i, player_dest: Vector2i) -> void:
	state = State.PULL
	velocity = Vector2.ZERO
	block.move_to(block_dest, GRAB_MOVE_TIME)
	var tw := create_tween()
	tw.tween_property(self, "global_position", room.cell_to_pos(player_dest), GRAB_MOVE_TIME)
	await tw.finished
	if state == State.PULL:
		state = State.NORMAL


# --- Combate ---------------------------------------------------------------------------------
func _attack() -> void:
	state = State.ATTACK
	velocity = Vector2.ZERO
	_sword_hit.clear()
	sword_hitbox.position = Vector2(facing) * float(Room.TILE)
	sword_shape.set_deferred("disabled", false)

	var attack_anim: StringName = ANIM_ATTACK.get(facing, &"Attack Down_right")
	var duration := SWORD_TIME
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(attack_anim):
		sprite.stop()
		sprite.frame = 0
		sprite.play(attack_anim)
		var fps := sprite.sprite_frames.get_animation_speed(attack_anim) * absf(sprite.speed_scale)
		if fps > 0.0:
			var total_units := 0.0
			for i in sprite.sprite_frames.get_frame_count(attack_anim):
				total_units += sprite.sprite_frames.get_frame_duration(attack_anim, i)
			duration = maxf(SWORD_TIME, total_units / fps)

	await get_tree().create_timer(duration).timeout
	sword_shape.set_deferred("disabled", true)
	if state == State.ATTACK:
		state = State.NORMAL


func _on_sword_body_entered(body: Node) -> void:
	if body is Enemy and not _sword_hit.has(body.get_instance_id()):
		_sword_hit[body.get_instance_id()] = true
		body.take_damage(1, global_position)


func _shoot() -> void:
	state = State.SHOOT
	velocity = Vector2.ZERO
	bow_cd = BOW_COOLDOWN
	var arrow: Arrow = ARROW_SCENE.instantiate()
	arrow.direction = Vector2(facing)
	room.add_child(arrow)
	arrow.global_position = global_position + Vector2(facing) * 12.0

	var shoot_anim: StringName = ANIM_SHOOT.get(facing, &"Bow_Attack_Down")
	var duration := BOW_TIME
	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation(shoot_anim):
		sprite.stop()
		sprite.frame = 0
		sprite.play(shoot_anim)
		var fps := sprite.sprite_frames.get_animation_speed(shoot_anim) * absf(sprite.speed_scale)
		if fps > 0.0:
			var total_units := 0.0
			for i in sprite.sprite_frames.get_frame_count(shoot_anim):
				total_units += sprite.sprite_frames.get_frame_duration(shoot_anim, i)
			duration = maxf(BOW_TIME, total_units / fps)
	bow_cd = maxf(BOW_COOLDOWN, duration)

	await get_tree().create_timer(duration).timeout
	if state == State.SHOOT:
		state = State.NORMAL


func take_damage(amount: int, from_pos: Vector2) -> void:
	if invuln > 0.0 or state == State.DEAD or state == State.LOCKED:
		return
	Game.damage(amount)
	invuln = INVULN_TIME
	if state == State.NORMAL:
		knock = (global_position - from_pos).normalized() * 240.0
		knock_time = 0.12
	if Game.hp <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	sprite.modulate = Color(1.0, 0.4, 0.4)
	died.emit()


# --- Lava ------------------------------------------------------------------------------------
func _burn() -> void:
	var dir := Vector2(facing)
	if velocity.length() > 1.0:
		if absf(velocity.x) > absf(velocity.y):
			dir = Vector2(signf(velocity.x), 0.0)
		else:
			dir = Vector2(0.0, signf(velocity.y))
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	global_position -= dir * 8.0
	if room != null and room.is_lava(room.pos_to_cell(global_position + Vector2(0, 6))):
		global_position = last_safe_pos
	take_damage(1, global_position + dir)


func _track_safe(delta: float) -> void:
	safe_timer -= delta
	if safe_timer > 0.0:
		return
	safe_timer = 0.15
	var c := room.pos_to_cell(global_position)
	for d in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if room.is_lava(c + d):
			return
	last_safe_pos = global_position


# --- Animacion -------------------------------------------------------------------------------
func _find_animated_sprite() -> AnimatedSprite2D:
	for child in get_children():
		if child is AnimatedSprite2D:
			return child
	return null


func _update_sprite() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var is_attacking := state == State.ATTACK
	var is_shooting := state == State.SHOOT
	var scale_mult := attack_scale_mult if is_attacking else (bow_scale_mult if is_shooting else 1.0)
	sprite.scale = _base_sprite_scale * scale_mult
	sprite.offset = _base_sprite_offset + (attack_offset if is_attacking else Vector2.ZERO)

	var anim: StringName = ANIM_IDLE.get(facing, &"iso_idle_down_right")
	if is_attacking:
		anim = ANIM_ATTACK.get(facing, &"Attack Down_right")
	elif is_shooting:
		anim = ANIM_SHOOT.get(facing, &"Bow_Attack_Down")
	elif state == State.PULL or velocity.length() > 1.0:
		anim = ANIM_WALK.get(facing, &"iso_walk_down_right")

	if sprite.sprite_frames.has_animation(anim):
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)
	_update_back_gear()


func _update_back_gear() -> void:
	var bob := sin(walk_clock * 14.0) * 1.0 if velocity.length() > 1.0 else 0.0
	if back_sword != null:
		back_sword.visible = Game.has_item("sword") and state != State.ATTACK
		if back_sword.visible:
			back_sword.modulate = sprite.modulate
			match facing:
				Vector2i.UP:
					back_sword.z_index = 1
					back_sword.position = Vector2(7.0, 8.0 + bob)
					back_sword.rotation_degrees = 100.0
					back_sword.flip_h = false
				Vector2i.DOWN:
					back_sword.z_index = 1
					back_sword.position = Vector2(-7.0, 8.0 + bob)
					back_sword.rotation_degrees = 170.0
					back_sword.flip_h = false
				Vector2i.LEFT:
					back_sword.z_index = -1
					back_sword.position = Vector2(3.0, 8.0 + bob)
					back_sword.rotation_degrees = 110.0
					back_sword.flip_h = false
				Vector2i.RIGHT:
					back_sword.z_index = 1
					back_sword.position = Vector2(-2.0, 8.0 + bob)
					back_sword.rotation_degrees = 160.0
					back_sword.flip_h = false

	if back_bow != null:
		back_bow.visible = Game.has_item("bow") and state != State.SHOOT
		if back_bow.visible:
			back_bow.modulate = sprite.modulate
			match facing:
				Vector2i.UP:
					back_bow.z_index = 1
					back_bow.position = Vector2(0.0, 1.0 + bob)
					back_bow.rotation_degrees = -18.0
					back_bow.flip_h = false
				Vector2i.DOWN:
					back_bow.z_index = -1
					back_bow.position = Vector2(0.0, -2.0 + bob)
					back_bow.rotation_degrees = 18.0
					back_bow.flip_h = true
				Vector2i.LEFT:
					back_bow.z_index = -1
					back_bow.position = Vector2(5.0, 0.0 + bob)
					back_bow.rotation_degrees = 12.0
					back_bow.flip_h = false
				Vector2i.RIGHT:
					back_bow.z_index = -1
					back_bow.position = Vector2(-5.0, 0.0 + bob)
					back_bow.rotation_degrees = -12.0
					back_bow.flip_h = true
