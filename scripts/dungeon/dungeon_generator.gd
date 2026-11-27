extends Node2D

# The Arena Below - Dungeon Generator
# Purpose: Generates rooms, room types, obstacles,
# walls, and collision bodies.
#
# References:
# https://docs.godotengine.org/en/stable/classes/class_rect2i.html
# https://docs.godotengine.org/en/stable/classes/class_staticbody2d.html
# https://docs.godotengine.org/en/stable/tutorials/math/random_number_generation.html
# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html

# Dungeon settings.
@export_range(3, 30) var room_count: int = 8
@export var tile_size: int = 20

# Room dimensions.
@export var room_min_width: int = 18
@export var room_max_width: int = 28

@export var room_min_height: int = 12
@export var room_max_height: int = 18

@export_range(1, 4) var wall_thickness: int = 1

# Obstacle settings
@export var obstacle_min_count: int = 3
@export var obstacle_max_count: int = 6

@export var obstacle_min_size: int = 1
@export var obstacle_max_size: int = 1

@export_group("Obstacle Collisions")

@export var pillar_collision_size: Vector2 = Vector2(14, 8)
@export var pillar_collision_offset: Vector2 = Vector2(0, 0)

@export var crate_collision_size: Vector2 = Vector2(18, 18)
@export var barrel_collision_size: Vector2 = Vector2(16, 16)

@export_range(1, 5) var obstacle_spacing: int = 3

# Reward room settings.
@export_range(0.0, 1.0) var reward_room_chance: float = 0.35
@export_range(3, 10) var combat_rooms_per_reward: int = 3

# Grid tile types.
const FLOOR: int = 0
const OBSTACLE: int = 1

# Obstacle textures
const CRATE_TEXTURE = preload(
    "res://art/dungeon/obstacles/crate.png"
)

const BARREL_TEXTURE = preload(
    "res://art/dungeon/obstacles/barrel.png"
)

const PILLAR_TEXTURE = preload(
	"res://art/dungeon/obstacles/column.png"
)

# Available room types.
enum RoomType {
	START,
	COMBAT,
	REWARD,
	TRANSITION
}

# Dungeon information.
var rooms: Array[Rect2i] = []
var room_types: Array[RoomType] = []

var current_room_index: int = 0

var obstacles: Array[Rect2i] = []
var dungeon_grid: Array = []

var exit_locked: bool = false

# Scene references
@onready var wall_collisions: Node2D = $WallCollisions
@onready var floor_tiles: TileMapLayer = $FloorTiles
@onready var wall_tiles: TileMapLayer = $WallTiles

@onready var obstacle_graphics: Node2D = $ObstacleGraphics

# Dungeon graphics
const TILE_SOURCE_ID: int = 1

const FLOOR_PRIMARY: Vector2i = Vector2i(1, 4)
const FLOOR_ALTERNATIVE: Vector2i = Vector2i(3, 4)
const FLOOR_CRACKED: Vector2i = Vector2i(2, 4)
const FLOOR_DAMAGED: Vector2i = Vector2i(1, 5)

const WALL_TILE: Vector2i = Vector2i(2, 1)

# Separate random generator for visual variation.
var graphics_rng: RandomNumberGenerator = RandomNumberGenerator.new()

# --------------------------------------------------
# ROOM TYPE HELPERS
# --------------------------------------------------
func get_current_room_type() -> RoomType:
	return room_types[current_room_index]

func is_start_room() -> bool:
	return get_current_room_type() == RoomType.START

func is_combat_room() -> bool:
	return get_current_room_type() == RoomType.COMBAT

func is_reward_room() -> bool:
	return get_current_room_type() == RoomType.REWARD

func is_transition_room() -> bool:
	return get_current_room_type() == RoomType.TRANSITION

# --------------------------------------------------
# DUNGEON GENERATION
# --------------------------------------------------
# Generate a new dungeon
func generate_dungeon() -> void:
	rooms.clear()
	room_types.clear()

	current_room_index = 0

	# Validate the generation settings.
	if room_count < 3:
		push_error("Dungeon needs at least three rooms.")
		return

	if tile_size <= 0:
		push_error("Tile size must be positive.")
		return

	if room_min_width < 8 or room_min_height < 8:
		push_error("Room dimensions are too small.")
		return

	if room_max_width < room_min_width:
		push_error("Invalid room width settings.")
		return

	if room_max_height < room_min_height:
		push_error("Invalid room height settings.")
		return

	if obstacle_min_size < 1:
		push_error("Obstacle sizes must be positive.")
		return

	if obstacle_max_size < obstacle_min_size:
		push_error("Invalid obstacle size settings.")
		return

	# Generate the dimensions of each room.
	for i in range(room_count):

		var width: int = randi_range(
			room_min_width,
			room_max_width
		)

		var height: int = randi_range(
			room_min_height,
			room_max_height
		)

		# Center the room around the origin.
		var x: int = -int(width / 2.0)
		var y: int = -int(height / 2.0)

		rooms.append(
			Rect2i(x, y, width, height)
		)

	# Assign each room its type.
	generate_room_types()

	# Load the starting room.
	load_room(0)

	print(
		"Dungeon generated with ",
		rooms.size(),
        " rooms."
	)

	print_room_sequence()

# Randomly assign room types
func generate_room_types() -> void:
	room_types.clear()

	var combat_count: int = 0

	# Room one is always the starting room.
	room_types.append(RoomType.START)

	# Generate the intermediate rooms.
	for i in range(1, room_count - 1):

		var can_generate_reward: bool = (
			combat_count >= combat_rooms_per_reward
		)

		if can_generate_reward and randf() < reward_room_chance:

			room_types.append(RoomType.REWARD)

			# Require more combat rooms before
			# another reward can appear.
			combat_count = 0

		else:

			room_types.append(RoomType.COMBAT)

			combat_count += 1

	# The last room is always a reward room
	# that transitions directly into the arena.
	room_types.append(RoomType.TRANSITION)

# --------------------------------------------------
# ROOM LOADING
# --------------------------------------------------
# Load one room at a time.
func load_room(room_index: int) -> void:
	if room_index < 0 or room_index >= rooms.size():
		return

	current_room_index = room_index

	# Combat rooms require all enemies to be defeated.
	# Starting rooms will be locked later when
	# weapon selection is implemented.
	exit_locked = is_combat_room()

	# Remove the previous room's collision bodies.
	for child in wall_collisions.get_children():

		wall_collisions.remove_child(child)
		child.queue_free()

	obstacles.clear()
	dungeon_grid.clear()

	var room: Rect2i = rooms[current_room_index]

	# Create the floor grid.
	for y in range(room.size.y):

		var row: Array[int] = []

		for x in range(room.size.x):
			row.append(FLOOR)

		dungeon_grid.append(row)

	# Every room needs exterior walls.
	create_room_walls(room)

	# Only combat rooms contain random obstacles.
	if is_combat_room():
		generate_obstacles(room)

	# Generate room textures.
	generate_room_graphics(room)

	# Generate obstacle textures.
	generate_obstacle_graphics()

	queue_redraw()

	print(
		"Loaded room ",
		current_room_index + 1,
		" (",
		room.size.x,
		" x ",
		room.size.y,
        ")"
	)

	print(
		"Room type: ",
		RoomType.keys()[get_current_room_type()]
	)

	print("Obstacles: ", obstacles.size())

# --------------------------------------------------
# WALL COLLISIONS
# --------------------------------------------------
# Create four continuous walls around the room.
func create_room_walls(room: Rect2i) -> void:

	var thickness: float = wall_thickness * tile_size

	var left: float = room.position.x * tile_size
	var top: float = room.position.y * tile_size

	var width: float = room.size.x * tile_size
	var height: float = room.size.y * tile_size

	# Top wall.
	create_wall_collision(
		Vector2(
			left + width / 2.0,
			top - thickness / 2.0
		),
		Vector2(
			width + thickness * 2.0,
			thickness
		)
	)

	# Bottom wall.
	create_wall_collision(
		Vector2(
			left + width / 2.0,
			top + height + thickness / 2.0
		),
		Vector2(
			width + thickness * 2.0,
			thickness
		)
	)

	# Left wall.
	create_wall_collision(
		Vector2(
			left - thickness / 2.0,
			top + height / 2.0
		),
		Vector2(
			thickness,
			height
		)
	)

	# Right wall.
	create_wall_collision(
		Vector2(
			left + width + thickness / 2.0,
			top + height / 2.0
		),
		Vector2(
			thickness,
			height
		)
	)

# Create a rectangular wall collision body.
func create_wall_collision(
	wall_position: Vector2,
	wall_size: Vector2 ) -> void:

	var body: StaticBody2D = StaticBody2D.new()

	body.position = wall_position

	# Walls are on collision layer one.
	body.collision_layer = 1
	body.collision_mask = 0

	var shape_node: CollisionShape2D = (
		CollisionShape2D.new()
	)

	var rectangle: RectangleShape2D = (
		RectangleShape2D.new()
	)

	rectangle.size = wall_size

	shape_node.shape = rectangle

	body.add_child(shape_node)

	wall_collisions.add_child(body)

# --------------------------------------------------
# OBSTACLE GENERATION
# --------------------------------------------------
# Generate random obstacles inside combat rooms.
func generate_obstacles(room: Rect2i) -> void:
	var target_count: int = randi_range(
		obstacle_min_count,
		obstacle_max_count
	)

	var attempts: int = 0
	var max_attempts: int = 100

	while obstacles.size() < target_count and attempts < max_attempts:

		attempts += 1

		var width: int = randi_range(
			obstacle_min_size,
			obstacle_max_size
		)

		var height: int = randi_range(
			obstacle_min_size,
			obstacle_max_size
		)

		# Leave at least two tiles between obstacles
		# and exterior walls.
		var min_x: int = room.position.x + 2
		var max_x: int = room.end.x - width - 2

		var min_y: int = room.position.y + 2
		var max_y: int = room.end.y - height - 2

		# Skip obstacles that are too large.
		if max_x < min_x or max_y < min_y:
			continue

		var x: int = randi_range(min_x, max_x)
		var y: int = randi_range(min_y, max_y)

		var new_obstacle: Rect2i = Rect2i(
			x,
			y,
			width,
			height
		)

		# Prevent obstacles from overlapping.
		if obstacle_overlaps(new_obstacle):
			continue

		# Keep the player spawn and room exit clear.
		if obstacle_blocks_spawn_or_exit(new_obstacle):
			continue

		mark_obstacle(new_obstacle, OBSTACLE)

		# Make sure a path to the exit still exists.
		if not has_valid_path(room):

			mark_obstacle(new_obstacle, FLOOR)

			continue

		obstacles.append(new_obstacle)

# Create one continuous collision body per obstacle.
func create_obstacle_collision(
	obstacle: Rect2i,
	texture: Texture2D ) -> void:

	var body: StaticBody2D = StaticBody2D.new()

	# Center of the occupied tile.
	body.position = Vector2(
		(
			obstacle.position.x +
			obstacle.size.x / 2.0
		) * tile_size,
		(
			obstacle.position.y +
			obstacle.size.y / 2.0
		) * tile_size
	)

	body.collision_layer = 1
	body.collision_mask = 0

	var shape_node: CollisionShape2D = (
		CollisionShape2D.new()
	)

	var rectangle: RectangleShape2D = (
		RectangleShape2D.new()
	)

	# Choose the collision based on the obstacle.
	if texture == PILLAR_TEXTURE:

		rectangle.size = pillar_collision_size
		shape_node.position = pillar_collision_offset

	elif texture == CRATE_TEXTURE:

		rectangle.size = crate_collision_size

	elif texture == BARREL_TEXTURE:

		rectangle.size = barrel_collision_size

	else:

		rectangle.size = Vector2(
			obstacle.size.x * tile_size,
			obstacle.size.y * tile_size
		)

	shape_node.shape = rectangle

	body.add_child(shape_node)

	wall_collisions.add_child(body)

# Check whether an obstacle overlaps another obstacle.
func obstacle_overlaps(
	new_obstacle: Rect2i ) -> bool:

	for existing_obstacle in obstacles:

		var restricted_area: Rect2i = (
			existing_obstacle.grow(obstacle_spacing)
		)

		if restricted_area.intersects(new_obstacle):
			return true

	return false

# Prevent obstacles from blocking important positions.
func obstacle_blocks_spawn_or_exit(
	new_obstacle: Rect2i) -> bool:

	var spawn_tile: Vector2i = rooms[
		current_room_index
	].get_center()

	var exit_position: Vector2 = get_exit_position()

	var exit_tile: Vector2i = Vector2i(
		floori(exit_position.x / tile_size),
		floori(exit_position.y / tile_size)
	)

	# Leave extra space around the player spawn.
	if new_obstacle.grow(3).has_point(spawn_tile):
		return true

	# Leave extra space around the exit.
	if new_obstacle.grow(3).has_point(exit_tile):
		return true

	return false

# Mark obstacle tiles in the dungeon grid.
func mark_obstacle(
	obstacle: Rect2i,
	value: int ) -> void:

	var room: Rect2i = rooms[current_room_index]

	for y in range(
		obstacle.position.y,
		obstacle.end.y
	):

		for x in range(
			obstacle.position.x,
			obstacle.end.x
		):

			var local_x: int = x - room.position.x
			var local_y: int = y - room.position.y

			dungeon_grid[local_y][local_x] = value

# --------------------------------------------------
# PATH VALIDATION
# --------------------------------------------------
# Check whether the player can reach the exit.
# Uses breadth-first search.
func has_valid_path(room: Rect2i) -> bool:
	var start: Vector2i = room.get_center()

	var exit_position: Vector2 = get_exit_position()

	var goal: Vector2i = Vector2i(
		floori(exit_position.x / tile_size),
		floori(exit_position.y / tile_size)
	)

	var queue: Array[Vector2i] = [start]

	var visited: Dictionary = {}
	visited[start] = true

	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

	var queue_index: int = 0

	while queue_index < queue.size():

		var current: Vector2i = queue[queue_index]

		queue_index += 1

		# A path to the exit was found.
		if current == goal:
			return true

		for direction in directions:

			var neighbor: Vector2i = current + direction

			if not room.has_point(neighbor):
				continue

			if visited.has(neighbor):
				continue

			var local_x: int = (
				neighbor.x - room.position.x
			)

			var local_y: int = (
				neighbor.y - room.position.y
			)

			if dungeon_grid[local_y][local_x] == OBSTACLE:
				continue

			visited[neighbor] = true

			queue.append(neighbor)

	return false

# --------------------------------------------------
# ROOM POSITIONS AND PROGRESSION
# --------------------------------------------------
# Return the center of the current room.
func get_current_room_center() -> Vector2:

	var room: Rect2i = rooms[current_room_index]

	var center: Vector2i = room.get_center()

	return Vector2(
		(center.x + 0.5) * tile_size,
		(center.y + 0.5) * tile_size
	)

# Return the position of the room's exit.
func get_exit_position() -> Vector2:

	var room: Rect2i = rooms[current_room_index]

	return Vector2(
		(room.end.x - 0.5) * tile_size,
		(
			room.position.y +
			room.size.y / 2.0
		) * tile_size
	)

# Check whether another dungeon room exists.
func has_next_room() -> bool:

	return current_room_index < rooms.size() - 1

# Unlock the current room's exit.
func unlock_exit() -> void:

	if not exit_locked:
		return

	exit_locked = false

	queue_redraw()

	print("Room exit unlocked.")

# Lock the exit.
# This will also be used for weapon selection later.
func lock_exit() -> void:

	exit_locked = true

	queue_redraw()

# --------------------------------------------------
# ROOM GRAPHICS
# --------------------------------------------------
# Generate the floor and wall graphics.
func generate_room_graphics(room: Rect2i) -> void:
	floor_tiles.clear()
	wall_tiles.clear()

	# Debugging information.
	print("----- GRAPHICS DEBUG -----")
	print("Floor TileSet: ", floor_tiles.tile_set)
	print("Wall TileSet: ", wall_tiles.tile_set)

	if floor_tiles.tile_set == null:
		push_error("Floor TileSet is missing!")
		return

	if wall_tiles.tile_set == null:
		push_error("Wall TileSet is missing!")
		return

	print("Source count: ", floor_tiles.tile_set.get_source_count())

	for i in range(floor_tiles.tile_set.get_source_count()):
		print("Source ID: ", floor_tiles.tile_set.get_source_id(i))

	if floor_tiles.tile_set.has_source(TILE_SOURCE_ID):

		var atlas = floor_tiles.tile_set.get_source(TILE_SOURCE_ID)

		print("Primary floor exists: ", atlas.has_tile(FLOOR_PRIMARY))
		print("Alternative floor exists: ", atlas.has_tile(FLOOR_ALTERNATIVE))
		print("Cracked floor exists: ", atlas.has_tile(FLOOR_CRACKED))
		print("Damaged floor exists: ", atlas.has_tile(FLOOR_DAMAGED))
		print("Wall tile exists: ", atlas.has_tile(WALL_TILE))

	else:
		push_error("Incorrect TileSet source ID!")
		return

	generate_floor_tiles(room)
	generate_wall_tiles(room)

	print("Floor cells: ", floor_tiles.get_used_cells().size())
	print("Wall cells: ", wall_tiles.get_used_cells().size())

	print("--------------------------")

# --------------------------------------------------
# OBSTACLE GRAPHICS
# --------------------------------------------------
func clear_obstacle_graphics() -> void:
	for child in obstacle_graphics.get_children():

		obstacle_graphics.remove_child(child)
		child.queue_free()

func generate_obstacle_graphics() -> void:
	clear_obstacle_graphics()

	for obstacle in obstacles:

		var texture: Texture2D = (
			choose_obstacle_texture()
		)

		# Create the collision for this obstacle type.
		create_obstacle_collision(
			obstacle,
			texture
		)

		# Create the obstacle sprite.
		for y in range(
			obstacle.position.y,
			obstacle.end.y
		):

			for x in range(
				obstacle.position.x,
				obstacle.end.x
			):

				create_obstacle_sprite(
					Vector2i(x, y),
					texture
				)

func choose_obstacle_texture() -> Texture2D:
	var roll: float = graphics_rng.randf()

	# 70% chance of a pillar.
	if roll < 0.70:
		return PILLAR_TEXTURE

	# 15% chance of a crate.
	elif roll < 0.85:
		return CRATE_TEXTURE

	# 15% chance of a barrel.
	return BARREL_TEXTURE

func create_obstacle_sprite(
	tile: Vector2i,
	texture: Texture2D ) -> void:

	var sprite: Sprite2D = Sprite2D.new()

	sprite.texture = texture
	sprite.centered = true
	sprite.z_index = 0

	sprite.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	var texture_size: Vector2 = texture.get_size()

	# Preserve the original proportions.
	var sprite_scale: float = (
		float(tile_size) / texture_size.x
	)

	sprite.scale = Vector2(
		sprite_scale,
		sprite_scale
	)

	# Place the sorting origin near the obstacle base.
	sprite.position = Vector2(
		(tile.x + 0.5) * tile_size,
		(tile.y + 0.5) * tile_size
	)

	if texture == PILLAR_TEXTURE:
		sprite.position += pillar_collision_offset

	# Keep the bottom of the texture aligned
	# with the bottom of the occupied tile.
	sprite.offset = Vector2(
		0.0,
		(float(tile_size) / sprite_scale
		- texture_size.y) / 2.0
	)

	# Preserve the original visual position even
	# when the pillar collision has an offset.
	if texture == PILLAR_TEXTURE:
		sprite.offset -= (
			pillar_collision_offset / sprite_scale
		)

	obstacle_graphics.add_child(sprite)
	
	# Align the bottom of tall sprites with
	# the bottom of their collision tile.
	var sprite_height: float = (
		texture_size.y * sprite_scale
	)

	sprite.position.y -= (
		sprite_height - tile_size
	) / 2.0

	obstacle_graphics.add_child(sprite)

# Generate the floor of the current room.
func generate_floor_tiles(room: Rect2i) -> void:

	for y in range(room.position.y, room.end.y):

		for x in range(room.position.x, room.end.x):

			var tile_position: Vector2i = Vector2i(x, y)

			var atlas_position: Vector2i = get_random_floor_tile()

			floor_tiles.set_cell(
				tile_position,
				TILE_SOURCE_ID,
				atlas_position
			)

# Select a random floor texture.
func get_random_floor_tile() -> Vector2i:

	var chance: float = graphics_rng.randf()

	if chance < 0.70:
		return FLOOR_PRIMARY

	elif chance < 0.85:
		return FLOOR_ALTERNATIVE

	elif chance < 0.95:
		return FLOOR_CRACKED

	else:
		return FLOOR_DAMAGED

# Generate the exterior wall graphics.
func generate_wall_tiles(room: Rect2i) -> void:

	for layer in range(wall_thickness):

		var left: int = room.position.x - 1 - layer
		var right: int = room.end.x + layer

		var top: int = room.position.y - 1 - layer
		var bottom: int = room.end.y + layer

		# Generate top and bottom walls.
		for x in range(left, right + 1):

			place_wall_tile(x, top)
			place_wall_tile(x, bottom)

		# Generate left and right walls.
		for y in range(top + 1, bottom):

			place_wall_tile(left, y)
			place_wall_tile(right, y)

# Place an individual wall texture.
func place_wall_tile(x: int, y: int) -> void:

	wall_tiles.set_cell(
		Vector2i(x, y),
		TILE_SOURCE_ID,
		WALL_TILE
	)

# --------------------------------------------------
# DRAWING
# --------------------------------------------------
func _draw() -> void:
	if rooms.is_empty():
		return

	# --------------------------------------------------
	# EXIT MARKER
	# --------------------------------------------------

	var exit_color: Color = Color(0.1, 0.8, 0.3)

	# Purple indicates the final arena transition.
	if is_transition_room():

		exit_color = Color(0.7, 0.4, 0.9)

	# Red indicates a locked exit.
	if exit_locked:

		exit_color = Color(0.9, 0.15, 0.15)

	draw_rect(
		Rect2(
			get_exit_position() - Vector2(10, 10),
			Vector2(20, 20)
		),
		exit_color
	)

	# --------------------------------------------------
	# TEMPORARY ROOM TYPE MARKER
	# --------------------------------------------------

	var marker_color: Color = Color.WHITE

	match get_current_room_type():

		RoomType.START:
			marker_color = Color(0.2, 0.5, 0.9)

		RoomType.COMBAT:
			marker_color = Color(0.8, 0.2, 0.2)

		RoomType.REWARD:
			marker_color = Color(0.2, 0.8, 0.3)

		RoomType.TRANSITION:
			marker_color = Color(0.6, 0.3, 0.8)

	var marker_position: Vector2 = (
		get_current_room_center()
	)

	marker_position.y -= 50.0

	draw_circle(
		marker_position,
		12.0,
		marker_color
	)
	
	# --------------------------------------------------
	# EXIT MARKER
	# --------------------------------------------------

	#var exit_color: Color = Color(0.1, 0.8, 0.3)

	# Purple indicates the final arena transition.
	if is_transition_room():

		exit_color = Color(0.7, 0.4, 0.9)

	# Red indicates a locked exit.
	if exit_locked:

		exit_color = Color(0.9, 0.15, 0.15)

	draw_rect(
		Rect2(
			get_exit_position() - Vector2(10, 10),
			Vector2(20, 20)
		),
		exit_color
	)

	# --------------------------------------------------
	# TEMPORARY ROOM TYPE MARKER
	# --------------------------------------------------

	#var marker_color: Color = Color.WHITE

	match get_current_room_type():

		RoomType.START:
			marker_color = Color(0.2, 0.5, 0.9)

		RoomType.COMBAT:
			marker_color = Color(0.8, 0.2, 0.2)

		RoomType.REWARD:
			marker_color = Color(0.2, 0.8, 0.3)

		RoomType.TRANSITION:
			marker_color = Color(0.6, 0.3, 0.8)

	#var marker_position: Vector2 = (
		#get_current_room_center()
	#)

	marker_position.y -= 50.0

	draw_circle(
		marker_position,
		12.0,
		marker_color
	)

# Draw one wall tile.
func draw_wall_tile(x: int, y: int) -> void:

	draw_rect(
		Rect2(
			x * tile_size,
			y * tile_size,
			tile_size - 1,
			tile_size - 1
		),
		Color(0.25, 0.25, 0.25)
	)

# --------------------------------------------------
# DEBUGGING
# --------------------------------------------------
# Print the current room's boundaries.
func print_current_room_bounds() -> void:

	var room: Rect2i = rooms[current_room_index]

	print("Room index: ", current_room_index)

	print("Room tile bounds: ", room)

	print(
		"Room pixel bounds: ",
		Rect2(
			Vector2(room.position) * tile_size,
			Vector2(room.size) * tile_size
		)
	)

# Print the complete dungeon room sequence.
func print_room_sequence() -> void:

	print("----- DUNGEON ROOM SEQUENCE -----")

	for i in range(room_types.size()):

		print(
			"Room ",
			i + 1,
			": ",
			RoomType.keys()[room_types[i]]
		)

	print("---------------------------------")
