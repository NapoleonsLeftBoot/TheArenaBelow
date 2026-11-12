class_name PlayerAttackState
extends PlayerState

const HURTBOX_MASK: int = 1 << 2 #needed to put hurtbox in layer 4 ):

@export var move_data: MoveData

var tick: int = 0
var hit_targets: Array[Node] = []

var _shape := RectangleShape2D.new()
var _query := PhysicsShapeQueryParameters2D.new()

func _ready() -> void:
	_query.shape = _shape
	_query.collision_mask = HURTBOX_MASK
	_query.collide_with_areas = true
	_query.collide_with_bodies = false

func enter() -> void:
	super()
	tick = 0
	hit_targets.clear()
	player.crouch = move_data.crouch
	if player.animation.has_animation(move_data.animation):
		player.animation.play(move_data.animation)

func exit(new_state: State = null) -> void:
	super(new_state)
	
	player.fast_falling = false
	player.hitfall_buffered = false
	if move_data.crouch:
		player.crouch = false
	player.show_hitboxes([])
	

func process_physics(delta: float) -> State:
	if move_data.aerial:
		do_air_move(delta)
		
	else:
		player.velocity.x *= move_data.traction
		
	var next_state: State = super(delta)
	tick += 1

	if move_data.aerial and player.is_on_floor():
		return land_state
	
	if player.velocity.y > 0 and player.buffer.consume(down_key):
		player.fast_falling = true
		
	if player.fast_falling:
		player.velocity.y = move_toward(player.velocity.y, fast_fall_velocity, fast_fall_accel * delta)

	_update_hitboxes()
	if tick >= move_data.total_frames:
		if not player.is_on_floor():
			return fall_state
		if move_data.crouch and player.is_held(down_key):
			return crouch_state
		return idle_state
	return next_state

func _update_hitboxes() -> void:
	var facing: int = -1 if sprite_flipped else 1
	var live: Array[Rect2] = []
	for box in move_data.hitboxes:
		if tick < box.start_tick or tick >= box.end_tick:
			continue
		var center: Vector2 = player.global_position + Vector2(box.offset.x * facing, box.offset.y)
		live.append(Rect2(center - box.size / 2.0, box.size))
		_hit_check(box, center, facing)
	player.show_hitboxes(live)

func _hit_check(box: HitboxData, center: Vector2, facing: int) -> void:
	_shape.size = box.size
	_query.transform = Transform2D(0.0, center)
	var results: Array[Dictionary] = player.get_world_2d().direct_space_state.intersect_shape(_query)
	for result in results:
		var area := result["collider"] as Area2D
		if area == null:
			continue
		var target: Node = area.get_parent()
		if target == player or hit_targets.has(target):
			continue
		if target.has_method("take_hit"):
			hit_targets.append(target)
			target.take_hit(box, facing)
			#if target is blocking then
			player.apply_hitfreeze(box.hitfreeze_frames)
