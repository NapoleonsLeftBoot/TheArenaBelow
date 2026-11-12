class_name PlayerState
extends State

#@onready var player: Player = get_tree().get_first_node_in_group("Player")
@onready var player: Player = get_parent().get_parent() as Player

#General Mvmt Attributes
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", -9.8)
var Speed: float = 630
var Air_speed: float = 585
var Air_acceleration: float = 1800
var traction: float = .75
var crouch_traction: float = 0.7
var block_traction: float = 0.7


@export var auto_face: bool = false

#Hit Attributes
var hitstun_friction: float = 2700
var di_max_angle: float = 18.0 

#Jump Attributes
var squat_duration: float = 0.08
var full_hop_velocity: float = -1575
var short_hop_velocity: float = -1125
var jump_squat_traction: float = 0.95
var land_duration: float = 0.1
var land_traction: float = .9

#Walljump Attributes
var wall_jump_speed: Vector2 = Vector2(990, -1450.0)
var min_income_speed: float = 50.0
var wall_jump_lockout: int = 8                 


#Animation Names
var idle_anim: String = "idle"
var walk_anim: String = "walk"
var jump_squat_anim: String = "jump_squat"
var jump_anim: String = "jump"
var fall_anim: String = "fall"
var land_anim: String = "land"
var crouch_anim: String = "crouch"
var hitstun_anim: String = "hitstun"
var ko_anim: String = "ko"




#States
@export_group("states")
@export var idle_state: PlayerState
@export var walk_state: PlayerState
@export var jump_squat_state: PlayerState
@export var jump_state: PlayerState
@export var fall_state: PlayerState
@export var land_state: PlayerState
@export var dash_state: PlayerState
@export var light_state: PlayerState
@export var medium_state: PlayerState
@export var heavy_state: PlayerState
@export var air_light_state: PlayerState
@export var air_medium_state: PlayerState
@export var air_heavy_state: PlayerState
@export var crouch_state: PlayerState
@export var walljump_state: PlayerState
@export var block_state: PlayerState
@export var crouch_block_state: PlayerState
@export var crouch_light_state: PlayerState
@export var crouch_medium_state: PlayerState
@export var crouch_heavy_state: PlayerState
@export var parry_state: PlayerState

#State Variables
var sprite_flipped: bool = false

#Input Keys
var movement_key: String = "movement"
var left_key: String = "Left"
var right_key: String = "Right"
var jump_key: String = "Jump"
var down_key: String = "Down"
var dash_key: String = "Dash"
var light_key: String = "Light"
var medium_key: String = "Medium"
var heavy_key: String = "Heavy"
var block_key: String = "Block"

#Fall Attributes
var terminal_velocity: float = 1575
var fast_fall_velocity: float = 2500
var fast_fall_accel: float = 8100

#Dash Attributes
var dash_speed: float = 1575
var dash_end_speed: float = 1260
var dash_decel: float = 4500
var dash_frames: int  = 16
var min_dash_frames: int = 2


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
	var left_held = player.is_held(left_key)
	var right_held = player.is_held(right_key)
	
	if left_held and right_held:
		if player.just_pressed(right_key):
			return 1.0
		elif player.just_pressed(left_key):
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


func face_move_dir() -> void:
	var dir: float = get_move_dir()
	if dir == 0.0:
		return
	sprite_flipped = dir < 0.0
	player.sprite.flip_h = sprite_flipped
	

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

func start_attack(attack_state: PlayerAttackState, move: MoveData) -> State:
	if move == null:
		return null

	attack_state.move_data = move
	return attack_state
