class_name PlayerHitstunState
extends PlayerState

var tick: int = 0

func enter() -> void:
	super()
	tick = 0
	player.fast_falling = false
	player.buffer.clear()
	if player.animation.has_animation(hitstun_anim):
		player.animation.play(hitstun_anim)

func process_physics(delta: float) -> State:
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, hitstun_friction * delta)
	var next_state: State = super(delta)
	tick += 1

	if tick >= player.hitstun_ticks:
		if not player.is_on_floor():
			return fall_state
		return walk_state if get_move_dir() != 0.0 else idle_state
	return next_state
