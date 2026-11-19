class_name PlayerHandPlantState
extends PlayerState

var handplant_timer: int = 0
var handplant_dir: float = 1.0

func enter() -> void:
	super()
	player.animation.play("handplant_catch")
	handplant_timer = 0
	handplant_dir = get_move_dir()
	if handplant_dir == 0.0:
		handplant_dir = -1.0 if sprite_flipped else 1.0
	player.velocity.x = 0

func process_physics(delta: float) -> State:
	player.move_and_slide()

	handplant_timer += 1

	if handplant_timer >= handplant_ticks:
		player.slide_dir = handplant_dir
		return hand_slide_state
	return null
