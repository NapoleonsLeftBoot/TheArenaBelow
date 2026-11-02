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
	if dash_dir == 0.0:
		dash_dir = -1.0 if sprite_flipped else 1.0
	sprite_flipped = dash_dir < 0.0
	player.sprite.flip_h = sprite_flipped
	player.animation.play(walk_anim)

func process_physics(delta: float) -> State:
	if braking:
		player.velocity.x = move_toward(player.velocity.x, 0.0, dash_decel * delta)
	else:
		player.velocity.x = dash_dir * dash_speed
	var next_state: State = super(delta)
	tick += 1

	if player.buffer.consume_big(jump_key):
		return jump_squat_state

	if not braking:
		var key_released: bool = tick >= min_dash_frames and not Input.is_action_pressed(dash_key)
		var timer_finished: bool = tick >= dash_frames

		if key_released or timer_finished:
			braking = true
	else:
		var current_speed: float = absf(player.velocity.x)

		if current_speed <= dash_end_speed:
			return land_state
	return next_state
