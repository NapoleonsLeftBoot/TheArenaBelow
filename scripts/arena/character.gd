class_name Player
extends CharacterBody2D

signal ko
signal health_changed(current: int, maximum: int)

@onready var state_machine: StateMachine = $"State Machine"
@onready var animation: AnimationPlayer = $Animation
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox_debug: Node2D = $HitboxDebug
@onready var jump_sound = $AudioStreamPlayer

@export var max_health: int = 100
var opponent: Player

@export var is_ai: bool = false
var ai_held: Dictionary = {}

# shared runtime state
var health: int = 100
var CROUCH_MULT_STN: float = 0.85
var CROUCH_MULT_x: float = 0.85
var CROUCH_MULT_y: float = 0.75
var BLOCK_MULT_X: float = 0.9
var BLOCK_MULT_STN: float = 0.6
var hitstun_ticks: int = 0
var blockstun_ticks: int = 0
var hitfreeze_ticks: int = 0
var is_ko: bool = false
var fast_falling: bool = false
var buffer: InputBuffer = InputBuffer.new()
var crouch: bool = false
var block: bool = false
var crouch_block: bool = false
var jump_start_x: float
var parry_window: int = 10;
var parry_tick_count: int = 0;
var parry: bool = false;
var di_input: Vector2 = Vector2.ZERO


func show_hitboxes(rects: Array[Rect2]) -> void:
	hitbox_debug.show_rects(rects)

func _ready():
	health = max_health
	state_machine.init()

func _process(delta):
	if hitfreeze_ticks > 0:
		return
	state_machine.process_frame(delta)
	

func _physics_process(delta):
	if hitfreeze_ticks > 0:
		_get_di()
		hitfreeze_ticks -= 1
		if hitfreeze_ticks == 0:
			animation.speed_scale = 1.0
			sprite.speed_scale = 1.0
		return
	_update_facing()
	state_machine.process_physics(delta)


func _input(event):
	if is_ai:
		return
	buffer.record(event)
	state_machine.process_input(event)

func take_hit(move: HitboxData, facing: int) -> void:
	if is_ko:
		return
		
	if can_block(move):
		if parry_tick_count <= parry_window:
			apply_hitfreeze(ceil(move.hitfreeze_frames / 2))
			parry = true;
			return
		else:
			apply_hitfreeze(move.hitfreeze_frames)
			velocity.x = (ceil(move.knockback.x * facing * BLOCK_MULT_X))
			blockstun_ticks = ceil(move.hitstun_frames * BLOCK_MULT_STN)
			return
	health -= move.damage
	health_changed.emit(maxi(health, 0), max_health)
	if crouch:
		apply_hitfreeze(move.hitfreeze_frames)
		velocity = Vector2(ceil(move.knockback.x * facing * CROUCH_MULT_x), ceil(move.knockback.y * CROUCH_MULT_y))
		hitstun_ticks = ceil(move.hitstun_frames * CROUCH_MULT_STN) 
	else:
		apply_hitfreeze(move.hitfreeze_frames)
		velocity = Vector2(move.knockback.x * facing, move.knockback.y)
		hitstun_ticks = move.hitstun_frames

	if health <= 0:
		is_ko = true
		state_machine.change_state(state_machine.ko_state)
		ko.emit()
		return
	di_input = Vector2.ZERO
	state_machine.change_state(state_machine.hitstun_state)

func is_held(action: String) -> bool:
	if is_ai:
		return ai_held.get(action, false)
	return Input.is_action_pressed(action)
	

func just_pressed(action: String) -> bool:
	if is_ai:
		return false
	return Input.is_action_just_pressed(action)

func face(dir: float) -> void:
	if dir == 0.0:
		return
	var flipped: bool = dir < 0.0
	sprite.flip_h = flipped
	(state_machine.current_state as PlayerState).sprite_flipped = flipped

func _update_facing() -> void:
	if opponent == null or not is_instance_valid(opponent):
		opponent = _find_opponent()
	if opponent == null:
		return
	var current := state_machine.current_state as PlayerState
	if current == null or not current.auto_face:
		return
	var dx: float = opponent.global_position.x - global_position.x
	if absf(dx) < 4.0:
		return 
	face(signf(dx))

func _find_opponent() -> Player:
	for node in get_tree().get_nodes_in_group("Player"):
		if node != self and node is Player:
			return node
	return null

func apply_hitfreeze(frames: int) -> void:
	if frames <= 0:
		return
	if hitfreeze_ticks <= 0:
		animation.speed_scale = 0.0
		sprite.speed_scale = 0.0
	hitfreeze_ticks = maxi(hitfreeze_ticks, frames)

func wall_side() -> int:
	if is_on_floor():
		return 0
	if test_move(global_transform, Vector2(-1, 0)):
		return -1
	if test_move(global_transform, Vector2(1, 0)):
		return 1
	return 0

func _get_di() -> void:
	if is_ai == true:
		return

	var d := Vector2.ZERO

	if is_held("Right") == true:
		d.x = 1.0

	if is_held("Left") == true:
		d.x -= 1.0

	if is_held("Down") == true:
		d.y = 1.0

	if is_held("Jump") == true:
		d.y -= 1.0

	if d != Vector2.ZERO:
		di_input = d

func can_block(move: HitboxData) -> bool:
	if move.hit_attribute == "Low":
		if crouch_block == true:
			return true
		else:
			return false

	elif move.hit_attribute == "High":
		if block == true:
			return true
		else:
			return false


	else:
		if block == true:
			return true
		else:
			return false
