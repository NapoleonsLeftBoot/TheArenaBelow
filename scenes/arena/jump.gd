class_name PlayerJumpState
extends PlayerState

var squat_timer: float = 0.00
var jump_button_held: bool = true;

func enter() -> void:
	super()
	player.animation.play(jump_anim)
	
func exit(new_state: State = null) -> void:
		super(new_state)
		#pass

	
func process_physics(delta: float) -> State:
	do_air_move(delta)
	var next_state: State = super(delta)
	if player.velocity.y > 0.0:
		return fall_state
	return null
