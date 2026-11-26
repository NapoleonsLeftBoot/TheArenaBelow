class_name PlayerDashState
extends PlayerState

var tick: int = 0
var dash_dir: float = 1.0
var braking: bool = false

func enter() -> void:
	super()
	tick = 0
	braking = false
	dash_dir = get_move_dir()
	var relation: int = dash_relation()
		
	if dash_dir == 0.0:
		if sprite_flipped:
			dash_dir = -1.0   #left
		else:
			dash_dir = 1.0 #riht
	if relation == 1:
		player.animation.play(player.current_moveset.dash.animation)
	elif relation == -1:
		if player.animation.has_animation(player.current_moveset.back_dash.animation):
			player.animation.play(player.current_moveset.back_dash.animation)
func process_physics(delta: float) -> State:
	if braking:
		player.velocity.x *= dash_traction
	else:
		player.velocity.x = dash_dir * dash_speed
	var next_state: State = super(delta)
	tick += 1

	if player.buffer.consume_big(jump_key):
		return jump_squat_state

	if not braking:
		var key_released: bool = tick >= min_dash_ticks and not player.is_held(dash_key)
		var timer_finished: bool = tick >= dash_ticks

		if key_released or timer_finished:
			braking = true
	else:
		var current_speed: float = absf(player.velocity.x)

		if current_speed <= dash_end_speed:
			return land_state
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
	
