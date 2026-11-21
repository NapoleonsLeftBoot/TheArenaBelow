class_name PlayerAttackState
extends PlayerState

const HURTBOX_MASK: int = 1 << 2 #needed to put hurtbox in layer 4 ):
var active_hitbox_index: int = -1
var hit_connected: bool = false
@export var move_data: MoveData

var tick: int = 0
var hit_targets: Dictionary = {}
var has_hit: bool = false

var _shape := RectangleShape2D.new()
var _query := PhysicsShapeQueryParameters2D.new()

func _ready() -> void:
	_query.shape = _shape
	_query.collision_mask = HURTBOX_MASK
	_query.collide_with_areas = true
	_query.collide_with_bodies = false

func enter() -> void:
	super()
	hit_connected = false
	tick = 0
	hit_targets.clear()
	has_hit = false
	player.crouch = move_data.crouch
	if player.animation.has_animation(move_data.animation):
		player.animation.play(move_data.animation)

func exit(new_state: State = null) -> void:
	super(new_state)
	
	player.fast_falling = false
	player.hitfall_buffered = false
	if move_data.crouch and (new_state is not PlayerCrouchState):
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
	
	if move_data.aerial:
		if has_hit:
			if player.buffer.consume(down_key) or player.hitfall_buffered:
				player.fast_falling = true
				player.hitfall_buffered = false
		else:
			if player.velocity.y > 0.0 and player.buffer.consume(down_key):
				player.fast_falling = true
				
		if player.fast_falling:
			player.velocity.y = move_toward(player.velocity.y, fast_fall_velocity,fast_fall_accel * delta)
	
	_update_hitboxes()
	var new_state: State = _try_cancel()
	if new_state:
		return new_state
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

	var group: int = box.hit_group

	if not hit_targets.has(group):
		hit_targets[group] = []

	for result in results:
		var area := result["collider"] as Area2D
		if area == null:
			continue

		var target: Node = area.get_parent()

		if target == player or hit_targets[group].has(target):
			continue

		if target.has_method("take_hit"):
			hit_targets[group].append(target)
			target.take_hit(box, facing)
			hit_connected = true
			has_hit = true
			player.apply_hitfreeze(box.hitfreeze_frames)

func _try_cancel() -> State:
	if not hit_connected:
		return null

	if tick < move_data.cancel_start or tick >= move_data.cancel_end:
		return null

	var ms = player.current_moveset
	

	# AERIALS
	if move_data.aerial:
		if ms.air_heavy.strength > move_data.strength:
			if player.buffer.consume_big(heavy_key):
				return start_attack(air_heavy_state, ms.air_heavy)

		if ms.air_medium.strength > move_data.strength:
			if player.buffer.consume_big(medium_key):
				return start_attack(air_medium_state, ms.air_medium)

		if ms.air_light.strength > move_data.strength:
			if player.buffer.consume_big(light_key):
				return start_attack(air_light_state, ms.air_light)

	# CROUCHING ATTACKS
	elif move_data.crouch:
		if ms.crouch_heavy.strength > move_data.strength:
			if player.buffer.consume_big(heavy_key):
				return start_attack(crouch_heavy_state, ms.crouch_heavy)

		if ms.crouch_medium.strength > move_data.strength:
			if player.buffer.consume_big(medium_key):
				return start_attack(crouch_medium_state, ms.crouch_medium)

		if ms.crouch_light.strength > move_data.strength:
			if player.buffer.consume_big(light_key):
				return start_attack(crouch_light_state, ms.crouch_light)
		
		if player.is_held(jump_key):
			return jump_squat_state

	# STANDING ATTACKS
	else:

		# Check for crouching attacks
		if player.is_held(down_key):

			if ms.crouch_heavy.strength > move_data.strength:
				if player.buffer.consume_big(heavy_key):
					return start_attack(crouch_heavy_state, ms.crouch_heavy)

			if ms.crouch_medium.strength > move_data.strength:
				if player.buffer.consume_big(medium_key):
					return start_attack(crouch_medium_state, ms.crouch_medium)

			if ms.crouch_light.strength > move_data.strength:
				if player.buffer.consume_big(light_key):
					return start_attack(crouch_light_state, ms.crouch_light)

		# Otherwise check standing attacks
		else:

			if ms.standing_heavy.strength > move_data.strength:
				if player.buffer.consume_big(heavy_key):
					return start_attack(heavy_state, ms.standing_heavy)

			if ms.standing_medium.strength > move_data.strength:
				if player.buffer.consume_big(medium_key):
					return start_attack(medium_state, ms.standing_medium)

			if ms.standing_light.strength > move_data.strength:
				if player.buffer.consume_big(light_key):
					return start_attack(light_state, ms.standing_light)

	return null
