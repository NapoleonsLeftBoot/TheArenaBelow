class_name PlayerWalkState
extends PlayerState

func enter()-> void:
	super()
	player.animation.play(walk_anim)
	#face_move_dir()
	
func exit(new_state: State = null)-> void:
	super(new_state)

func process_input(event: InputEvent) -> State:
	super(event)
	#if event.is_action_pressed(movement_key): determine_sprite_flipped(event.as_text())
	#if event.is_action_pressed(right_key): determine_sprite_flipped(event.as_text())
	return null

func process_physics(delta: float) -> State:
	#face_move_dir()
	do_move(get_move_dir())
	super(delta)
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
	if get_move_dir() != 0.0 and player.buffer.consume(dash_key):
		return dash_state
	if get_move_dir() == 0.0:
		return idle_state
	return null
	
func do_move(move_dir: float) -> void:
	#flip state
	player.velocity.x = move_dir * Speed
