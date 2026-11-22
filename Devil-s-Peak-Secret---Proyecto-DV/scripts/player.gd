class_name Player
extends CharacterBody2D
## Jacob, el protagonista: movimiento, espada, arco, empujar/halar bloques y dano.

signal died

enum State { NORMAL, ATTACK, SHOOT, PULL, DEAD, LOCKED }

const SPEED := 72.0
const SWORD_TIME := 0.24
const BOW_TIME := 0.25
const BOW_COOLDOWN := 0.5
const PUSH_DELAY := 0.22        # tiempo empujando contra un bloque antes de que se mueva
const GRAB_MOVE_TIME := 0.28    # duracion de un paso al empujar/halar con E
const INVULN_TIME := 1.0
const ARROW_SCENE := preload("res://scenes/projectiles/arrow.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var sword_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var slash: Sprite2D = $SwordHitbox/Slash

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


func _ready() -> void:
	sword_shape.disabled = true
	slash.visible = false
	sword_hitbox.body_entered.connect(_on_sword_body_entered)


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
		if room.is_lava(room.pos_to_cell(global_position + Vector2(0, 3))):
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
	if perp > 6.0:
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
	var f := Vector2(facing)
	sword_hitbox.position = f * 11.0
	slash.rotation = f.angle()
	slash.visible = true
	sword_shape.set_deferred("disabled", false)
	await get_tree().create_timer(SWORD_TIME).timeout
	sword_shape.set_deferred("disabled", true)
	slash.visible = false
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
	arrow.global_position = global_position + Vector2(facing) * 6.0
	await get_tree().create_timer(BOW_TIME).timeout
	if state == State.SHOOT:
		state = State.NORMAL


func take_damage(amount: int, from_pos: Vector2) -> void:
	if invuln > 0.0 or state == State.DEAD or state == State.LOCKED:
		return
	Game.damage(amount)
	invuln = INVULN_TIME
	if state == State.NORMAL:
		knock = (global_position - from_pos).normalized() * 120.0
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
	global_position = last_safe_pos
	take_damage(1, global_position + Vector2(0, -1))


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
func _update_sprite() -> void:
	var row := 0
	if facing == Vector2i.UP:
		row = 1
	elif facing == Vector2i.LEFT:
		row = 2
	elif facing == Vector2i.RIGHT:
		row = 3
	var col := 0
	if state == State.ATTACK:
		col = 2
	elif state == State.SHOOT:
		col = 3
	elif state == State.PULL or velocity.length() > 1.0:
		col = int(walk_clock * 8.0) % 2
	sprite.frame = row * 4 + col
