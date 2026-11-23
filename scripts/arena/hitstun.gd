class_name PlayerHitstunState
extends PlayerState

var impact_vel: float = 0.0

func enter() -> void:
	super()
	player.remaining_hitstun = player.hitstun_ticks
	impact_vel = 0.0
	player.fast_falling = false
	player.buffer.clear()
	
	if player.hit_in_crouch == false:
		if player.animation.has_animation(crouch_anim):
			player.animation.play(crouch_anim)


func process_physics(delta: float) -> State:
	if player.remaining_hitstun == player.hitstun_ticks:
		_apply_di()

	impact_vel = maxf(impact_vel, player.velocity.y)

	var next_state: State = super(delta)

	if player.is_on_floor():

		if impact_vel >= min_impact_vel and not player.has_bounced:
			return bounce_state
		return ground_slide_state

	if player.remaining_hitstun > 0:
		player.remaining_hitstun -= 1

	if player.remaining_hitstun <= 0:
		return fall_state

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
