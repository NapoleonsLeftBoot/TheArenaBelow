class_name PlayerWalljumpState
extends PlayerState

var tick: int = 0
var freeze_frames: int = 8
var facing_wall: bool = false

func enter() -> void:
	super()
	tick = 0
	var side: int = player.wall_side()
	
	player.velocity = Vector2.ZERO
	player.fast_falling = false
	
	#walljump facing away from wall
	if (sprite_flipped and side == 1) or ((not sprite_flipped) and side == -1):
		player.animation.play(player.current_moveset.away_walljump_squat.animation)
	#walljump facing towards wall
	else:
		facing_wall = true
		player.animation.play(player.current_moveset.walljump_squat.animation)
	
func process_physics(delta: float) -> State:
	
	tick += 1

	if tick <= freeze_frames:
		player.velocity = Vector2.ZERO
		return null

	if tick == freeze_frames + 1:
		var side: int = player.wall_side()
		player.velocity = Vector2(-side * wall_jump_speed.x, wall_jump_speed.y)

	var next_state: State = super(delta)

	if tick >= wall_jump_lockout:
		if facing_wall:
			player.transition_anim = player.current_moveset.walljump_to_fall.animation
		else:
			player.transition_anim = player.current_moveset.away_walljump_to_fall.animation
		return jump_state

	return next_state
