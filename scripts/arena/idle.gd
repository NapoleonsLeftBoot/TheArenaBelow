class_name PlayerIdleState
extends PlayerState

func enter() -> void:
	if player.transition_anim != &"":
		player.animation.play(player.transition_anim)
		player.animation.queue(idle_anim)
		player.transition_anim = &""
	else:
		player.animation.play(idle_anim)
	
func exit(new_state: State = null) -> void:
		super(new_state)
	
func process_input(event: InputEvent) -> State:
	super(event)
	if event.is_action_pressed(movement_key): 
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
		return start_attack(light_state, player.current_moveset.standing_light)
	if player.buffer.consume(medium_key):
		return start_attack(medium_state, player.current_moveset.standing_medium)
	if player.buffer.consume(heavy_key):
		return start_attack(heavy_state, player.current_moveset.standing_heavy)
	if get_move_dir() != 0.0 and player.buffer.consume(dash_key):
		return dash_state
	if get_move_dir() != 0.0:
		return walk_state
	return null
