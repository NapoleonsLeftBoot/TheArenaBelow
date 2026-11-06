class_name Player
extends CharacterBody2D

signal ko
signal health_changed(current: int, maximum: int)

@onready var state_machine: StateMachine = $"State Machine"
@onready var animation: AnimationPlayer = $Animation
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

@export var max_health: int = 100
var opponent: Player

@export var is_ai: bool = false
var ai_held: Dictionary = {}

# shared runtime state
var health: int = 100
var hitstun_ticks: int = 0
var hitfreeze_ticks: int = 0
var is_ko: bool = false
var fast_falling: bool = false
var buffer: InputBuffer = InputBuffer.new()

func _ready():
	health = max_health
	state_machine.init()

func _process(delta):
	if hitfreeze_ticks > 0:
		return
	state_machine.process_frame(delta)

func _physics_process(delta):
	if hitfreeze_ticks > 0:
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

func take_hit(move: MoveData, facing: int) -> void:
	if is_ko:
		return
	health -= move.damage
	health_changed.emit(maxi(health, 0), max_health)
	apply_hitfreeze(move.hitfreeze_frames)
	velocity = Vector2(move.knockback.x * facing, move.knockback.y)
	hitstun_ticks = move.hitstun_frames
	print(name, " hit! health = ", health)

	if health <= 0:
		print("player ko'd")
		is_ko = true
		state_machine.change_state(state_machine.ko_state)
		ko.emit()
		return
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
