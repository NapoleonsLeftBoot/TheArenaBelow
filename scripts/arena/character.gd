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

@export var is_ai: bool = false
var ai_held: Dictionary = {}

# shared runtime state
var health: int = 100
var hitstun_ticks: int = 0
var is_ko: bool = false
var fast_falling: bool = false
var buffer: InputBuffer = InputBuffer.new()

func _ready():
	health = max_health
	state_machine.init()

func _process(delta): state_machine.process_frame(delta)

func _physics_process(delta):
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
