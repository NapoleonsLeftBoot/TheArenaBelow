class_name PlayerState
extends State

@onready var player: Player = get_tree().get_first_node_in_group("Player")

#General Mvmt Attributes
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", -9.8)
var Speed: float = 140
var Air_speed: float = 130
var Air_acceleration: float = 400.0

#Jump Attributes
var squat_duration: float = 0.08
var full_hop_velocity: float = -350.0
var short_hop_velocity: float = -250.0
var jump_squat_traction: float = 0.9
var land_duration: float = 0.05
var land_traction: float = .9


#Animation Names
var idle_anim: String = "idle"
var walk_anim: String = "walk"
var jump_squat_anim: String = "jump_squat"
var jump_anim: String = "jump"
var fall_anim: String = "fall"
var land_anim: String = "land"

#States
@export_group("states")
@export var idle_state: PlayerState
@export var walk_state: PlayerState
@export var jump_squat_state: PlayerState
@export var jump_state: PlayerState
@export var fall_state: PlayerState
@export var land_state: PlayerState

#State Variables
var sprite_flipped: bool = false

#Input Keys
var movement_key: String = "movement"
var left_key: String = "Left"
var right_key: String = "Right"
var jump_key: String = "Jump"

#Input Action
var left_actions: Array = InputMap.action_get_events(left_key).map(func(action: InputEvent) -> String: return action.as_text().get_slice(" -", 0))
var right_actions: Array = InputMap.action_get_events(right_key).map(func(action: InputEvent) -> String: return action.as_text().get_slice(" -", 0))

#util Fn
func determine_sprite_flipped(event_text: String) -> void:
	if left_actions.find(event_text) != -1: sprite_flipped = true
	elif right_actions.find(event_text) != -1: sprite_flipped = false
	player.sprite.flip_h = sprite_flipped
	pass
	
func get_move_dir() -> float:
	var left_held = Input.is_action_pressed(left_key)
	var right_held = Input.is_action_pressed(right_key)
	
	if left_held and right_held:
		if Input.is_action_just_pressed(right_key):
			return 1.0
		elif Input.is_action_just_pressed(left_key):
			return -1.0
		
		if player.velocity.x > 0:
			return 1.0
		elif player.velocity.x < 0:
			return -1.0
			
	if left_held:
		return -1.0
	elif right_held:
		return 1.0
		
	return 0.0

func do_air_move(delta: float) -> void:
	var move_dir: float = get_move_dir()
	if move_dir == 0.0:
		return
	var same_direction: bool = sign(player.velocity.x) == move_dir
	var past_air_speed: bool = abs(player.velocity.x) > Air_speed
	if not (same_direction and past_air_speed):
		player.velocity.x = move_toward(player.velocity.x, move_dir * Air_speed, Air_acceleration * delta)
#Base fn
func process_physics(delta: float) -> State:
	player.velocity.y += gravity * delta
	player.move_and_slide()
	return null

func exit(new_state: State = null) -> void:
	super()
	new_state.sprite_flipped = sprite_flipped
