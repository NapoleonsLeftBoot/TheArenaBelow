class_name PlayerFallState
extends PlayerState

func enter() -> void:
	super()
	player.animation.play(fall_anim)

func process_physics(delta: float) -> State:
	do_air_move(delta)
	var next_state: State = super(delta)
	if player.is_on_floor():
		return land_state
	return null
