class_name PlayerGroundSlideState
extends PlayerState

func enter() -> void:
	super()

	if player.animation.has_animation("ground_slide"):
		player.animation.play("ground_slide")


func process_physics(delta: float) -> State:

	player.velocity.x *= hitstun_traction

	var next_state: State = super(delta)

	if player.remaining_hitstun > 0:
		player.remaining_hitstun -= 1
		return next_state

	if player.is_held(down_key):
		return crouch_state
	if get_move_dir() != 0.0:
		return walk_state
	return idle_state
