class_name PlayerCrouchState
extends PlayerState



func enter() -> void:
	player.animation.play(crouch_anim)
	
func exit(new_state: State = null) -> void:
		super(new_state)
		#pass
	
func process_input(event: InputEvent) -> State:
	super(event)
	return null

func process_physics(delta: float) -> State:
	super(delta)
	player.velocity.x *= crouch_traction
	if not Input.is_action_pressed(down_key):
		return idle_state
	return null
