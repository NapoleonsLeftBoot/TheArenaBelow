class_name PlayerParryState
extends PlayerState

func enter() -> void:
	player.jump_sound.play()

func exit(new_state: State = null) -> void:
		super(new_state)
		#pass
	
func process_input(event: InputEvent) -> State:
	super(event)
	return null

func process_physics(delta: float) -> State:
	var next_state: State = super(delta)
	return idle_state
	return next_state
