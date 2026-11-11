class_name PlayerFallState
extends PlayerState

func enter() -> void:
	super()
	player.animation.play(fall_anim)

func process_physics(delta: float) -> State:
	do_air_move(delta)

	if player.velocity.y > 0.0 and player.buffer.consume(down_key):
		player.fast_falling = true

	if player.fast_falling:
		player.velocity.y = move_toward(player.velocity.y, fast_fall_velocity, fast_fall_accel * delta)
	else:
		player.velocity.y = min(player.velocity.y, terminal_velocity)
	
	var next_state: State = super(delta)
	if not player.is_on_floor() and player.buffer.consume(light_key):
		return air_light_state
	var side: int = player.wall_side()
	if side != 0 and get_move_dir() == -side and player.buffer.consume(jump_key):
		return walljump_state
	if player.is_on_floor():
		player.fast_falling = false
		return land_state
	return null
