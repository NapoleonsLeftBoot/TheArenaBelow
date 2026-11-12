class_name PlayerCrouchState
extends PlayerState



func enter() -> void:
	player.crouch = true;
	player.animation.play(crouch_anim)
	
func exit(new_state: State = null) -> void:
		super(new_state)
		player.crouch = false;
		#pass
	
func process_input(event: InputEvent) -> State:
	super(event)
	return null

func process_physics(delta: float) -> State:
	super(delta)
	player.velocity.x *= crouch_traction
	if player.is_held(block_key):
			return crouch_block_state
	if player.buffer.consume(light_key):
		return crouch_light_state
	if player.buffer.consume(medium_key):
		return crouch_medium_state
	if player.buffer.consume(heavy_key):
		return crouch_heavy_state
	if not player.is_held(down_key):
		return idle_state
	return null
