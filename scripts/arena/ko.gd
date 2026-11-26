class_name PlayerKOState
extends PlayerState

func enter() -> void:
	super()
	player.fast_falling = false
	player.buffer.clear()
	player.animation.play(player.current_moveset.ko.animation)

func process_physics(delta: float) -> State:
	if player.is_on_floor():
		player.velocity.x *= hitstun_traction
	return super(delta) 
