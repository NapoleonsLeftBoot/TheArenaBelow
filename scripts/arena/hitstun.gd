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
	if tick == 0:
		_apply_di()
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, hitstun_friction * delta)
	var next_state: State = super(delta)
	tick += 1

	if tick >= player.hitstun_ticks:
		if not player.is_on_floor():
			return fall_state
		if player.is_held(down_key):
			return crouch_state
		if get_move_dir() != 0.0:
			return walk_state
		else:
			return idle_state
	return next_state

func _apply_di() -> void:
	var held: Vector2 = player.di_input
	player.di_input = Vector2.ZERO
	if held == Vector2.ZERO:
		return

	var v: Vector2 = player.velocity
	if v == Vector2.ZERO:
		return

	var launch_dir: Vector2 = v.normalized()
	var perp := Vector2(-launch_dir.y, launch_dir.x)
	var amount: float = held.normalized().dot(perp)

	player.velocity = v.rotated(amount * deg_to_rad(di_max_angle))
