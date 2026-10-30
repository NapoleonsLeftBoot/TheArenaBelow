class_name PlayerIdleState
extends PlayerState

func enter() -> void:
	player.velocity.x = 0.0
	player.animation.play(idle_anim)
	
func exit(new_state: State = null) -> void:
		super(new_state)
		#pass
	
func process_input(event: InputEvent) -> State:
	super(event)
	if event.is_action_pressed(movement_key): 
		determine_sprite_flipped(event.as_text())
		return walk_state
	return null

func process_physics(delta: float) -> State:
	super(delta)
	if player.buffer.consume(jump_key):
		return jump_squat_state
	return null
