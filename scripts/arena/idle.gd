class_name PlayerIdleState
extends PlayerState

func enter() -> void:
	player.animation.play(idle_anim)
	
func exit(new_state: State = null) -> void:
		super(new_state)
		#pass
	
func process_input(event: InputEvent) -> State:
	super(event)
	if event.is_action_pressed(movement_key): 
		#determine_sprite_flipped(event.as_text())
		return walk_state
	return null

func process_physics(delta: float) -> State:
	super(delta)
	player.velocity.x *= traction
	if player.buffer.consume(jump_key):
		return jump_squat_state
	if player.buffer.consume(block_key):
		return block_state
	if player.buffer.consume(down_key):
		return crouch_state
	if player.buffer.consume(light_key):
		return light_state
	if player.buffer.consume(medium_key):
		return medium_state
	if player.buffer.consume(heavy_key):
		return heavy_state
	if get_move_dir() != 0.0 and player.buffer.consume(dash_key):
		return dash_state
	if get_move_dir() != 0.0:
		return walk_state
	return null
