extends Node2D

# Ranged enemy projectile.
# Travels in a straight line and stops on impact.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 160.0
var damage: int = 8
var lifetime: float = 2.0
var hit_radius: float = 10.0

var target: Node2D


func setup(
	player: Node2D,
	shot_direction: Vector2,
	shot_damage: int
) -> void:

	target = player
	direction = shot_direction.normalized()
	damage = shot_damage


func _ready() -> void:
	z_index = 10


func _physics_process(delta: float) -> void:

	lifetime -= delta

	if lifetime <= 0.0:
		queue_free()
		return

	if not is_instance_valid(target):
		queue_free()
		return

	if target.get("defeated") == true:
		queue_free()
		return

	var next_position: Vector2 = (
		global_position + direction * speed * delta
	)

	# Check for walls and obstacles.
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		next_position
	)

	query.collision_mask = 1

	var result: Dictionary = (
		get_world_2d().direct_space_state.intersect_ray(query)
	)

	if not result.is_empty():
		queue_free()
		return

	# Check whether the projectile crossed the player.
	var closest_point: Vector2 = (
		Geometry2D.get_closest_point_to_segment(
			target.global_position,
			global_position,
			next_position
		)
	)

	if closest_point.distance_to(
		target.global_position
	) <= hit_radius:

		target.call("take_damage", damage)

		queue_free()
		return

	global_position = next_position


func _draw() -> void:

	# Outer fireball.
	draw_circle(
		Vector2.ZERO,
		5.0,
		Color("#B83D20")
	)

	# Inner flame.
	draw_circle(
		Vector2.ZERO,
		3.5,
		Color("#FF852E")
	)

	# Bright center.
	draw_circle(
		Vector2.ZERO,
		1.5,
		Color("#FFE18A")
	)

	# Small flame trail.
	draw_line(
		-direction * 9.0,
		Vector2.ZERO,
		Color("#FF852E"),
		3.0
	)
