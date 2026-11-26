class_name PlayerHandSlideState
extends PlayerState

var tick: int = 0
var dash_dir: float = 1.0
var braking: bool = false

func enter() -> void:
	super()
	tick = 0
	braking = false
	dash_dir = get_move_dir()
		
	if player.slide_dir != 0:
		dash_dir = player.slide_dir
		player.slide_dir = 0.0
	else:
		dash_dir = get_move_dir()
		if dash_dir == 0.0:
			if sprite_flipped:
				dash_dir = -1.0
			else:
				dash_dir = 1.0
		
	var relation: int = dash_relation()
	
	if relation == 1:
		player.animation.play(player.current_moveset.land_dash.animation)
		player.current_moveset
	elif relation == -1:
		player.animation.play(player.current_moveset.back_dash.animation)
		
	player.velocity.x = dash_dir * dash_speed

func process_physics(delta: float) -> State:
	var next_state: State = super(delta)
	player.velocity.x *= handslide_traction
	tick += 1
	
	if player.buffer.consume(jump_key):
		return jump_squat_state
 
	if tick >= handslide_ticks:
		if player.buffer.consume_big(down_key):
			return crouch_state
		return idle_state
	return next_state

func dash_relation() -> int:
	var opp: Player = player.opponent
	if opp == null or not is_instance_valid(opp):
		return 0
	var distance: float = opp.global_position.x - player.global_position.x
	if distance == 0:
		return 0
	if (distance > 0) and (dash_dir > 0):
		return 1
	if (distance < 0) and (dash_dir < 0):
		return 1
	return -1
	
