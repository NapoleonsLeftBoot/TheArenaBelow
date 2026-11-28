class_name PlayerLandState
extends PlayerState

var land_timer: int = 0

func enter() -> void:
	super()
	land_timer = 0
	player.animation.play(player.current_moveset.land.animation)

func exit(new_state: State = null) -> void:
	super(new_state)
	if new_state is PlayerIdleState:
		player.transition_anim = player.current_moveset.land_to_idle.name

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
		return idle_state
		
	return next_state
