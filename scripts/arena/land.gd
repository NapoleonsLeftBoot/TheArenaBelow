class_name PlayerLandState
extends PlayerState

var land_timer: int = 0

func enter() -> void:
	super()
	land_timer = 0
	player.animation.play(land_anim)

func exit(new_state: State = null) -> void:
	super(new_state)
	if new_state is PlayerIdleState:
		player.transition_anim = land_to_idle_anim

func process_physics(delta: float) -> State:
	player.velocity.x *= land_traction
	var next_state: State = super(delta)
	land_timer += 1
	
	if player.buffer.consume(jump_key):
		return jump_squat_state
	if player.is_held(down_key):
		player.crouch = true
		return crouch_state
	
	if land_timer >= land_ticks:
		return walk_state if get_move_dir() != 0.0 else idle_state
	return next_state
