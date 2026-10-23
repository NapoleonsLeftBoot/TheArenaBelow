class_name PlayerJSquatState
extends PlayerState

var squat_timer: float = 0.00
var jump_button_held: bool = true;

func enter() -> void:
	super()
	player.animation.play(jump_squat_anim)
	squat_timer = squat_duration
	jump_button_held = true
	
func exit(new_state: State = null) -> void:
		super(new_state)
		#pass
	
func process_input(event: InputEvent) -> State:
	super(event)
	
	if event.is_action_released("Jump"):
		jump_button_held = false
	return null

func process_frame(delta: float) -> State:
	squat_timer -= delta
	
	if squat_timer <= 0.0:
		if jump_button_held:
			player.velocity.y = full_hop_velocity
		else:
			player.velocity.y = short_hop_velocity
		return jump_state
	return null
	
func process_physics(delta: float) -> State:
	player.velocity.x *= jump_squat_traction
	player.move_and_slide()
	return null
