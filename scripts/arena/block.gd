class_name PlayerBlockState
extends PlayerState



func enter() -> void:
	player.block = true;
	player.animation.play(fall_anim)
	
func exit(new_state: State = null) -> void:
		super(new_state)
		if not (new_state is PlayerBlockState or new_state is PlayerCrouchBlockState):
			player.parry_tick_count = 0
		player.block = false;
		#pass
	
func process_input(event: InputEvent) -> State:
	super(event)
	return null

func process_physics(delta: float) -> State:
	var next_state: State = super(delta)
	player.parry_tick_count += 1
	
	if player.parry == true:
		player.parry = false
		return parry_state

	player.velocity.x *= block_traction
	if player.blockstun_ticks > 0:
		player.blockstun_ticks -= 1
		return next_state
		
	if not player.is_held(block_key):
		if get_move_dir() != 0.0:
			return walk_state
		else:
			return idle_state
	if player.is_held(down_key):
		return crouch_block_state
	return next_state
