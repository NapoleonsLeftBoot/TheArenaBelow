class_name PlayerBounceState
extends PlayerState

func enter() -> void:
	player.has_bounced = true
	player.velocity.x = player.velocity.x * 0.4
	player.velocity.y = -bounce_up * 4
	player.animation.play(player.current_moveset.walljump.animation)

func process_physics(delta: float) -> State:
	var next_state: State = super(delta)
	if player.is_on_floor():
		return land_state
	return next_state
