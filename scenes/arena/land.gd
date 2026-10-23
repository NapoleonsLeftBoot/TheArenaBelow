class_name PlayerLandState
extends PlayerState

var land_timer: float = 0.0

func enter() -> void:
	super()
	player.animation.play(land_anim)
	land_timer = land_duration

func process_frame(delta: float) -> State:
	land_timer -= delta
	if land_timer <= 0.0:
		return walk_state if get_move_dir() != 0.0 else idle_state
	return null

func process_physics(delta: float) -> State:
	player.velocity.x *= land_traction
	return super(delta)
