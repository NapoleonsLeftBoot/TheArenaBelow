class_name PlayerJSquatState
extends PlayerState

var squat_timer: int = 0
var jump_button_held: bool = true;

func enter() -> void:
	super()
	player.animation.play(jump_squat_anim)
	squat_timer = 0
	jump_button_held = true
	
func exit(new_state: State = null) -> void:
		super(new_state)
		#pass

func process_physics(delta: float) -> State:
	player.velocity.x *= jump_squat_traction
	player.move_and_slide()
	squat_timer += 1

	if squat_timer >= squat_ticks:
		if player.is_held(jump_key):
			player.velocity.y = full_hop_velocity
		else:
			player.velocity.y = short_hop_velocity
		return jump_state
	return null
