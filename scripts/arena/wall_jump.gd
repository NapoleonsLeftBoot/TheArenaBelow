class_name PlayerWalljumpState
extends PlayerState

var tick: int = 0
var freeze_frames: int = 5

func enter() -> void:
	super()
	tick = 0

	player.velocity = Vector2.ZERO
	player.fast_falling = false
	player.animation.play(jump_anim)

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
		return jump_state

	return next_state
