class_name PlayerGroundSlideState
extends PlayerState
var active_traction: float = 0.0
var against_traction: float = 0.7 * hitstun_traction
var with_traction: float = 1.01 * hitstun_traction

func enter() -> void:
	super()

	if player.animation.has_animation("ground_slide"):
		player.animation.play("ground_slide")


func process_physics(delta: float) -> State:
	if get_move_dir() == 0:
		player.velocity.x *= hitstun_traction

	if (get_move_dir() != signf(player.velocity.x)):
		player.velocity.x *=  hitstun_traction
	if (get_move_dir() == signf(player.velocity.x)):
		player.velocity.x *=  with_traction

	var next_state: State = super(delta)

	if player.remaining_hitstun > 0:
		player.remaining_hitstun -= 1
		return next_state

	if player.is_held(down_key):
		return crouch_state
	if get_move_dir() != 0.0:
		return walk_state
	return idle_state
