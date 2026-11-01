class_name PlayerJabState
extends PlayerState

@export var move_data: MoveData

var tick: int = 0
var hit_targets: Array[Node] = []

func enter() -> void:
	super()
	tick = 0
	hit_targets.clear()

	if player.animation.has_animation(move_data.animation):
		player.animation.play(move_data.animation)

	# size and place of hitbox for move
	var facing: int = -1 if sprite_flipped else 1
	(player.hitbox_shape.shape as RectangleShape2D).size = move_data.hitbox_size 
	player.hitbox.position = Vector2(move_data.hitbox_offset.x * facing, move_data.hitbox_offset.y)

func exit(new_state: State = null) -> void:
	super(new_state)
	player.hitbox.monitoring = false
	player.hitbox_shape.set_deferred("disabled", true)

func process_physics(delta: float) -> State:
	if move_data.aerial:
		do_air_move(delta)
	else:
		player.velocity.x *= move_data.traction
	var next_state: State = super(delta)
	tick += 1

	# landing cancels an aerial move
	if move_data.aerial and player.is_on_floor():
		return land_state

	var active_start: int = move_data.startup_frames
	var active_end: int = active_start + move_data.active_frames
	var total: int = active_end + move_data.recovery_frames

	var is_active: bool = tick >= active_start and tick < active_end
	player.hitbox.monitoring = is_active
	player.hitbox_shape.set_deferred("disabled", not is_active)
	if is_active:
		check_hits()

	if tick >= total:
		if not player.is_on_floor():
			return fall_state
		#return walk_state if get_move_dir() != 0.0 else idle_state
		return idle_state
	return next_state

func check_hits() -> void:
	var facing: int = -1 if sprite_flipped else 1
	for area in player.hitbox.get_overlapping_areas():
		var target: Node = area.get_parent()
		if target == player or hit_targets.has(target):
			continue
		if target.has_method("take_hit"):
			hit_targets.append(target)
			target.take_hit(move_data, facing)
