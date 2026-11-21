
extends CharacterBody2D

# The Arena Below - Dungeon Enemy
# Handles three enemy types, grid navigation, health, and attacks.
#
# References:
# https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html
# https://docs.godotengine.org/en/stable/classes/class_vector2.html
#
# Keep enemy physics collisions disabled to preserve
# the working tile-based navigation system.


signal enemy_defeated


enum EnemyType {
	STANDARD,
	FAST,
	HEAVY
}


enum AttackState {
	CHASING,
	WINDUP,
	COOLDOWN
}


@export var enemy_type: EnemyType = EnemyType.STANDARD

# Movement settings.
@export var movement_speed: float = 60.0
@export var enemy_size: float = 14.0
@export var stopping_distance: float = 22.0
@export var movement_enabled: bool = true

# Health settings.
@export var max_health: int = 3

# Attack settings.
@export var attack_damage: int = 10
@export var attack_range: float = 28.0
@export var attack_windup: float = 0.4
@export var attack_cooldown: float = 1.5

# Enemy information.
var health: int
var defeated: bool = false

# Navigation references.
var target: Node2D
var dungeon_generator: Node2D
var path_grid: AStarGrid2D

# Grid information.
var tile_size: int = 20
var current_tile: Vector2i
var next_tile: Vector2i
var moving_to_tile: bool = false

# Combat information.
var attack_state: AttackState = AttackState.CHASING
var attack_timer: float = 0.0
var damage_flash_timer: float = 0.0


func _ready() -> void:
	z_index = 9

	configure_enemy_type()
	health = max_health

	add_to_group("dungeon_enemies")

	# Do not re-enable enemy collisions.
	collision_layer = 0
	collision_mask = 0

	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	$CollisionShape2D.disabled = true


# Assign stats based on the enemy's type.
func configure_enemy_type() -> void:
	match enemy_type:
		EnemyType.STANDARD:
			movement_speed = 60.0
			enemy_size = 14.0
			stopping_distance = 22.0
			max_health = 3
			attack_damage = 10
			attack_range = 28.0
			attack_windup = 0.4
			attack_cooldown = 1.5

		EnemyType.FAST:
			movement_speed = 90.0
			enemy_size = 11.0
			stopping_distance = 22.0
			max_health = 2
			attack_damage = 7
			attack_range = 28.0
			attack_windup = 0.25
			attack_cooldown = 0.9

		EnemyType.HEAVY:
			movement_speed = 42.0
			enemy_size = 20.0
			stopping_distance = 26.0
			max_health = 6
			attack_damage = 18
			attack_range = 32.0
			attack_windup = 0.7
			attack_cooldown = 2.2


# Initialize navigation information before spawning.
func setup(
	player: Node2D,
	generator: Node2D,
	navigation_grid: AStarGrid2D,
	spawn_tile: Vector2i,
	grid_tile_size: int
) -> void:
	target = player
	dungeon_generator = generator
	path_grid = navigation_grid

	tile_size = grid_tile_size
	current_tile = spawn_tile
	next_tile = spawn_tile
	moving_to_tile = false


func _physics_process(delta: float) -> void:
	if defeated:
		return

	if not is_instance_valid(target):
		return

	if target.get("defeated") == true:
		return

	if not is_instance_valid(dungeon_generator):
		return

	if path_grid == null:
		return

	damage_flash_timer = maxf(
		damage_flash_timer - delta,
		0.0
	)

	# Finish tile movement before starting an attack.
	# This preserves the existing navigation behavior.
	if moving_to_tile:
		if movement_enabled:
			move_to_next_tile(delta)

		queue_redraw()
		return

	match attack_state:
		AttackState.CHASING:
			handle_chasing()

		AttackState.WINDUP:
			handle_windup(delta)

		AttackState.COOLDOWN:
			handle_cooldown(delta)

	queue_redraw()


func handle_chasing() -> void:
	if can_attack_player():
		start_attack()
		return

	if not movement_enabled:
		return

	if global_position.distance_to(
		target.global_position
	) <= stopping_distance:
		return

	choose_next_tile()


func can_attack_player() -> bool:
	if not is_instance_valid(target):
		return false

	if target.get("defeated") == true:
		return false

	var distance: float = global_position.distance_to(
		target.global_position
	)

	if distance > attack_range:
		return false

	return has_clear_attack_path()


# Prevent attacks through walls and obstacles.
func has_clear_attack_path() -> bool:
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		target.global_position
	)

	query.collision_mask = 1
	query.exclude = [get_rid()]

	var result: Dictionary = (
		get_world_2d().direct_space_state.intersect_ray(query)
	)

	return result.is_empty()


func start_attack() -> void:
	attack_state = AttackState.WINDUP
	attack_timer = attack_windup


func handle_windup(delta: float) -> void:
	attack_timer -= delta

	if attack_timer > 0.0:
		return

	perform_attack()


func perform_attack() -> void:
	if can_attack_player():
		target.call("take_damage", attack_damage)

		print(
			name,
			" (",
			EnemyType.keys()[enemy_type],
			") attacked for ",
			attack_damage,
            " damage."
		)

	attack_state = AttackState.COOLDOWN
	attack_timer = attack_cooldown


func handle_cooldown(delta: float) -> void:
	attack_timer -= delta

	if attack_timer <= 0.0:
		attack_state = AttackState.CHASING


func get_player_tile() -> Vector2i:
	var local_position: Vector2 = (
		dungeon_generator.to_local(target.global_position)
	)

	return Vector2i(
		floori(local_position.x / tile_size),
		floori(local_position.y / tile_size)
	)


# Existing AStarGrid2D navigation.
func choose_next_tile() -> void:
	var player_tile: Vector2i = get_player_tile()

	if not path_grid.is_in_boundsv(current_tile):
		return

	if not path_grid.is_in_boundsv(player_tile):
		return

	if path_grid.is_point_solid(current_tile):
		return

	if path_grid.is_point_solid(player_tile):
		return

	var path: Array[Vector2i] = path_grid.get_id_path(
		current_tile,
		player_tile
	)

	if path.size() < 2:
		return

	var destination: Vector2i = path[1]

	if not path_grid.is_in_boundsv(destination):
		return

	if path_grid.is_point_solid(destination):
		return

	next_tile = destination
	moving_to_tile = true


# Move toward the next tile without move_and_slide().
func move_to_next_tile(delta: float) -> void:
	var destination: Vector2 = tile_to_world(next_tile)

	global_position = global_position.move_toward(
		destination,
		movement_speed * delta
	)

	if global_position.distance_to(destination) < 0.01:
		global_position = destination
		current_tile = next_tile
		moving_to_tile = false


func tile_to_world(tile: Vector2i) -> Vector2:
	var local_position: Vector2 = Vector2(
		(tile.x + 0.5) * tile_size,
		(tile.y + 0.5) * tile_size
	)

	return dungeon_generator.to_global(local_position)


func take_damage(amount: int) -> void:
	if defeated or amount <= 0:
		return

	health = maxi(health - amount, 0)
	damage_flash_timer = 0.15

	print(
		name,
		" (",
		EnemyType.keys()[enemy_type],
		") health: ",
		health,
		"/",
		max_health
	)

	queue_redraw()

	if health == 0:
		die()


func die() -> void:
	if defeated:
		return

	defeated = true
	moving_to_tile = false

	set_physics_process(false)
	remove_from_group("dungeon_enemies")
	hide()

	enemy_defeated.emit()
	queue_free()


func get_enemy_color() -> Color:
	match enemy_type:
		EnemyType.STANDARD:
			return Color(0.85, 0.2, 0.2)

		EnemyType.FAST:
			return Color(0.95, 0.6, 0.15)

		EnemyType.HEAVY:
			return Color(0.5, 0.35, 0.7)

	return Color.WHITE


func _draw() -> void:
	var half_size: float = enemy_size / 2.0
	var body_color: Color = get_enemy_color()

	match attack_state:
		AttackState.CHASING:
			body_color = get_enemy_color()

		AttackState.WINDUP:
			body_color = Color(1.0, 0.75, 0.1)

		AttackState.COOLDOWN:
			body_color = get_enemy_color().darkened(0.35)

	if damage_flash_timer > 0.0:
		body_color = Color.WHITE

	draw_rect(
		Rect2(
			-half_size,
			-half_size,
			enemy_size,
			enemy_size
		),
		body_color
	)

	# Attack range warning.
	if attack_state == AttackState.WINDUP:
		draw_arc(
			Vector2.ZERO,
			attack_range,
			0.0,
			TAU,
			32,
			Color(1.0, 0.75, 0.1, 0.8),
			2.0
		)

	# Health bar.
	var health_ratio: float = 0.0

	if max_health > 0:
		health_ratio = float(health) / float(max_health)

	draw_rect(
		Rect2(-10, -15, 20, 4),
		Color(0.25, 0.25, 0.25)
	)

	draw_rect(
		Rect2(-10, -15, 20 * health_ratio, 4),
		Color(0.2, 0.8, 0.2)
	)
