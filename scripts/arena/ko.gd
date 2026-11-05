class_name PlayerKOState
extends PlayerState

func enter() -> void:
	super()
	player.fast_falling = false
	player.buffer.clear()
	if player.animation.has_animation(ko_anim):
		player.animation.play(ko_anim)

func process_physics(delta: float) -> State:
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, hitstun_friction * delta)
	return super(delta) 
