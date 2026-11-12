class_name PlayerJumpState
extends PlayerState

var squat_timer: float = 0.00
var jump_button_held: bool = true;

func enter() -> void:
	super()
	player.jump_start_x = player.position.x
	player.animation.play(jump_anim)
	
func exit(new_state: State = null) -> void:
		super(new_state)
		#pass

	
func process_physics(delta: float) -> State:
	do_air_move(delta)
	var next_state: State = super(delta)
	
	if player.buffer.consume(light_key):
		return start_attack(air_light_state, player.current_moveset.air_light)
	if player.buffer.consume(medium_key):
		return start_attack(air_medium_state, player.current_moveset.air_medium)
	if player.buffer.consume(heavy_key):
		return start_attack(air_heavy_state, player.current_moveset.air_heavy)
		
	var side: int = player.wall_side()
	if side != 0 and get_move_dir() == -side and player.buffer.consume(jump_key):
		return walljump_state

	if player.velocity.y > 0.0:
		return fall_state
	return null
