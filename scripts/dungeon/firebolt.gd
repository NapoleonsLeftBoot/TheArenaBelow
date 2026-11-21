
extends Node2D

# The Arena Below - Firebolt
# A ranged magic projectile that damages one enemy.
#
# References:
# https://docs.godotengine.org/en/stable/classes/class_physicsdirectspacestate2d.html
# https://docs.godotengine.org/en/stable/classes/class_physicsrayqueryparameters2d.html


@export var movement_speed: float = 300.0
@export var projectile_radius: float = 6.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 2
var max_range: float = 180.0
var distance_traveled: float = 0.0

var active: bool = false


func setup(
	start_position: Vector2,
	travel_direction: Vector2,
	spell_damage: int,
	spell_range: float
) -> void:
	global_position = start_position
	direction = travel_direction.normalized()
	damage = spell_damage
	max_range = spell_range
	distance_traveled = 0.0
	active = true


func _physics_process(delta: float) -> void:
	if not active:
		return

	var remaining_range: float = (
		max_range - distance_traveled
	)

	if remaining_range <= 0.0:
		destroy()
		return

	var travel_distance: float = minf(
		movement_speed * delta,
		remaining_range
	)

	var next_position: Vector2 = (
		global_position + direction * travel_distance
	)

	# Check for walls and obstacles along the movement path.
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		next_position
	)

	query.collision_mask = 1

	var wall_hit: Dictionary = (
		get_world_2d().direct_space_state.intersect_ray(query)
	)

	var allowed_distance: float = travel_distance

	if not wall_hit.is_empty():
		allowed_distance = global_position.distance_to(
			wall_hit["position"]
		)

	# Find the first enemy along the projectile's path.
	var hit_enemy: Node2D = null
	var closest_hit_distance: float = INF

	for enemy in get_tree().get_nodes_in_group(
        "dungeon_enemies"
	):
		if not is_instance_valid(enemy):
			continue

		if enemy.is_queued_for_deletion():
			continue

		var to_enemy: Vector2 = (
			enemy.global_position - global_position
		)

		var along_path: float = (
			to_enemy.dot(direction)
		)

		if along_path < 0.0:
			continue

		if along_path > allowed_distance:
			continue

		var closest_point: Vector2 = (
			global_position + direction * along_path
		)

		var distance_from_path: float = (
			enemy.global_position.distance_to(
				closest_point
			)
		)

		var hit_radius: float = (
			projectile_radius + enemy.enemy_size / 2.0
		)

		if distance_from_path <= hit_radius:
			if along_path < closest_hit_distance:
				closest_hit_distance = along_path
				hit_enemy = enemy

	# Hit the nearest enemy before the wall.
	if hit_enemy != null:
		global_position += (
			direction * closest_hit_distance
		)

		hit_enemy.take_damage(damage)

		print("Firebolt hit enemy for ", damage, " damage.")

		destroy()
		return

	# Stop at a wall.
	if not wall_hit.is_empty():
		global_position = wall_hit["position"]
		destroy()
		return

	global_position = next_position
	distance_traveled += travel_distance

	if distance_traveled >= max_range:
		destroy()
		return

	queue_redraw()


func destroy() -> void:
	if not active:
		return

	active = false
	set_physics_process(false)
	queue_free()


func _draw() -> void:
	draw_circle(
		Vector2.ZERO,
		projectile_radius,
		Color(1.0, 0.45, 0.05)
	)

	draw_arc(
		Vector2.ZERO,
		projectile_radius + 3.0,
		0.0,
		TAU,
		24,
		Color(1.0, 0.8, 0.2, 0.7),
		2.0
	)
