class_name Player
extends CharacterBody2D

signal ko

@onready var state_machine: StateMachine = $"State Machine"
@onready var animation: AnimationPlayer = $Animation
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

@export var max_health: int = 100
@export var test_move: MoveData   #temp

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
	buffer.record(event)
	# temp
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H and test_move:
		take_hit(test_move, 1)
	state_machine.process_input(event)

func take_hit(move: MoveData, facing: int) -> void:
	if is_ko:
		return
	health -= move.damage
	velocity = Vector2(move.knockback.x * facing, move.knockback.y)
	hitstun_ticks = move.hitstun_frames
	print("player hit! health = ", health)

	if health <= 0:
		print("player ko'd")
		is_ko = true
		state_machine.change_state(state_machine.ko_state)
		ko.emit()
		return
	state_machine.change_state(state_machine.hitstun_state)
