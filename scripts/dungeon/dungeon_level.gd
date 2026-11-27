extends Node2D

# The Arena Below - Dungeon Level
# Manages room progression, combat, weapon selection,
# rewards, and randomized enemy types.
#
# Navigation reference:
# https://docs.godotengine.org/en/stable/classes/class_astargrid2d.html


enum EncounterState {
	LOCKED,
	UNLOCKED,
	COMPLETE,
	FAILED
}


const ENEMY_SCENE = preload(
	"res://scenes/dungeon/DungeonEnemy.tscn"
)

const PEDESTAL_SCENE = preload(
	"res://scenes/dungeon/weapon_pedestal.tscn"
)

const REWARD_PEDESTAL_SCENE = preload(
	"res://scenes/dungeon/reward_pedestal.tscn"
)

const FIREBOLT_SCENE = preload(
    "res://scenes/dungeon/firebolt.tscn"
)

const SWORD = preload(
	"res://resources/weapons/sword.tres"
)

const BATTLE_AXE = preload(
	"res://resources/weapons/battle_axe.tres"
)

const SPEAR = preload(
	"res://resources/weapons/spear.tres"
)

const FISTS = preload(
	"res://resources/weapons/fists.tres"
)


@export_group("Enemy Spawning")
@export var min_enemies: int = 2
@export var max_enemies: int = 4
@export var enemy_spawn_distance: float = 80.0
@export var enemy_spacing: float = 45.0
@export var enemy_movement_enabled: bool = true

# Relative weights, not percentages that must add to 100.
@export_group("Enemy Type Weights")
@export_range(0, 100) var standard_weight: int = 50
@export_range(0, 100) var fast_weight: int = 20
@export_range(0, 100) var heavy_weight: int = 15
@export_range(0, 100) var ranged_weight: int = 15

@export_group("Weapon Pedestals")
@export var pedestal_spacing: float = 75.0
@export var pedestal_vertical_offset: float = 55.0

@onready var dungeon_generator = $DungeonGenerator
@onready var dungeon_player = $DungeonPlayer
@onready var enemies: Node2D = $Enemies
@onready var weapon_pedestals: Node2D = $WeaponPedestals
@onready var reward_pedestals: Node2D = $RewardPedestals
@onready var hud = $HUD

var encounter_state: EncounterState = EncounterState.UNLOCKED
var transitioning: bool = false
var remaining_enemies: int = 0

var path_grid: AStarGrid2D

var nearest_pedestal: Node2D = null
var nearest_reward_pedestal: RewardPedestal = null

var reward_selected: bool = false

func _ready() -> void:
	# A new dungeon starts a fresh run.

	if not GameManager.run_started:
		GameManager.start_new_run()

	apply_difficulty_settings()
	
	RunData.restore_dungeon_player(dungeon_player)

	dungeon_player.health_changed.connect(
		hud.update_health
	)

	dungeon_player.player_defeated.connect(
		on_player_defeated
	)

	dungeon_player.weapon_equipped.connect(
		on_weapon_equipped
	)
	
	dungeon_player.firebolt_cast.connect(
		on_firebolt_cast
	)

	# Mana and magic HUD are updated by the player signals.
	dungeon_player.mana_changed.connect(hud.update_mana)
	dungeon_player.magic_cooldowns_changed.connect(hud.update_magic_cooldowns)
	dungeon_player.shield_started.connect(hud.on_shield_started)
	dungeon_player.shield_ended.connect(hud.on_shield_ended)


	hud.update_health(
		dungeon_player.health,
		dungeon_player.max_health
	)

	hud.update_mana(dungeon_player.mana, dungeon_player.max_mana)
	hud.update_magic_cooldowns(0.0, 0.0)
	hud.update_weapon(dungeon_player.current_weapon)
	hud.update_upgrades()

	dungeon_generator.generate_dungeon()
	
	dungeon_player.health_changed.connect(
		func(value: int, _maximum: int) -> void:
			RunData.save_health(value)
	)

	dungeon_player.mana_changed.connect(
		func(value: float, _maximum: float) -> void:
			RunData.save_mana(value)
	)

	if dungeon_generator.rooms.is_empty():
		push_error("Dungeon generation failed.")

		set_physics_process(false)
		dungeon_player.set_physics_process(false)
		return

	spawn_player()
	start_room_encounter()

func _physics_process(_delta: float) -> void:
	if transitioning or dungeon_player.defeated:
		return

	if dungeon_generator.is_start_room():
		update_weapon_interaction()

	if is_current_reward_room():
		update_reward_interaction()

	if encounter_state != EncounterState.UNLOCKED:
		return

	if dungeon_generator.exit_locked:
		return

	var exit_position: Vector2 = (
		dungeon_generator.to_global(
			dungeon_generator.get_exit_position()
		)
	)

	var distance: float = (
		dungeon_player.global_position.distance_to(
			exit_position
		)
	)

	if distance < 12.0:
		if dungeon_generator.has_next_room():
			advance_room()
		else:
			complete_dungeon()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return

	if event.physical_keycode != KEY_E:
		return

	if transitioning or dungeon_player.defeated:
		return

	if dungeon_generator.is_start_room():
		update_weapon_interaction()

		if is_instance_valid(nearest_pedestal):
			equip_nearest_weapon()
			get_viewport().set_input_as_handled()

	elif is_current_reward_room():
		if reward_selected:
			return

		update_reward_interaction()

		if is_instance_valid(nearest_reward_pedestal):
			select_nearest_reward()
			get_viewport().set_input_as_handled()

# --------------------------------------------------
# ROOM MANAGEMENT
# --------------------------------------------------
func is_current_reward_room() -> bool:
	return (
		dungeon_generator.is_reward_room()
		or dungeon_generator.is_transition_room()
	)

func get_current_room() -> Rect2i:
	return dungeon_generator.rooms[
		dungeon_generator.current_room_index
	]

func start_room_encounter() -> void:
	remaining_enemies = 0
	reward_selected = false

	
	if dungeon_generator.is_start_room():
		if dungeon_player.has_weapon():
			encounter_state = EncounterState.UNLOCKED
			dungeon_generator.unlock_exit()

			hud.show_interaction(
                "Weapon retained. Continue to the exit."
			)

			print("Existing weapon restored.")
		else:
			encounter_state = EncounterState.LOCKED
			dungeon_generator.lock_exit()

			spawn_weapon_pedestals()

			hud.show_interaction(
                "Choose a weapon to continue."
			)

			print("Starting room entered.")

	elif dungeon_generator.is_combat_room():
		encounter_state = EncounterState.LOCKED

		build_navigation_grid()
		spawn_enemies()

		print("Combat room started.")

	elif is_current_reward_room():
		encounter_state = EncounterState.LOCKED
		dungeon_generator.lock_exit()

		spawn_reward_pedestals()

		hud.show_interaction(
			"Choose one reward to continue."
		)

		if dungeon_generator.is_transition_room():
			print("Final reward room entered.")
		else:
			print("Reward room entered.")

func advance_room() -> void:
	if transitioning or dungeon_player.defeated:
		return

	if not dungeon_player.has_weapon():
		return

	transitioning = true
	call_deferred("load_next_room")

func load_next_room() -> void:
	if dungeon_player.defeated:
		transitioning = false
		return

	clear_enemies()
	clear_weapon_pedestals()
	clear_reward_pedestals()

	hud.hide_interaction()

	var next_index: int = (
		dungeon_generator.current_room_index + 1
	)

	dungeon_generator.load_room(next_index)

	spawn_player()
	start_room_encounter()

	print("Advanced to room ", next_index + 1)

	transitioning = false

func spawn_player() -> void:
	dungeon_player.global_position = (
		dungeon_generator.to_global(
			dungeon_generator.get_current_room_center()
		)
	)

	dungeon_player.velocity = Vector2.ZERO
	dungeon_player.reset_physics_interpolation()

# --------------------------------------------------
# WEAPON SELECTION
# --------------------------------------------------
func spawn_weapon_pedestals() -> void:
	clear_weapon_pedestals()

	var weapons: Array[WeaponData] = [
		SWORD,
		BATTLE_AXE,
		SPEAR,
		FISTS
	]

	var center: Vector2 = (
		dungeon_generator.get_current_room_center()
	)

	var room: Rect2i = get_current_room()

	var room_width: float = (
		room.size.x * dungeon_generator.tile_size
	)

	var room_height: float = (
		room.size.y * dungeon_generator.tile_size
	)

	var spacing: float = minf(
		pedestal_spacing,
		(room_width - 100.0) / 3.0
	)

	var vertical_offset: float = minf(
		pedestal_vertical_offset,
		room_height / 2.0 - 45.0
	)

	for i in range(weapons.size()):
		var pedestal = PEDESTAL_SCENE.instantiate()

		var offset_x: float = (
			(float(i) - 1.5) * spacing
		)

		var local_position: Vector2 = (
			center + Vector2(offset_x, -vertical_offset)
		)

		var world_position: Vector2 = (
			dungeon_generator.to_global(local_position)
		)

		pedestal.position = (
			weapon_pedestals.to_local(world_position)
		)

		pedestal.setup(weapons[i])
		weapon_pedestals.add_child(pedestal)

	print("Weapon pedestals spawned: 4")

func update_weapon_interaction() -> void:
	nearest_pedestal = null

	var nearest_distance: float = INF

	for pedestal in weapon_pedestals.get_children():
		if not pedestal.is_player_near(
			dungeon_player.global_position
		):
			continue

		var distance: float = (
			pedestal.global_position.distance_to(
				dungeon_player.global_position
			)
		)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_pedestal = pedestal

	for pedestal in weapon_pedestals.get_children():
		pedestal.set_highlighted(
			pedestal == nearest_pedestal
		)

	if is_instance_valid(nearest_pedestal):
		var weapon: WeaponData = (
			nearest_pedestal.get_weapon()
		)

		hud.show_interaction(
			"Press E: Equip " + weapon.weapon_name
		)

	elif dungeon_player.has_weapon():
		hud.show_interaction(
			"Weapon selected. Exit unlocked."
		)

	else:
		hud.show_interaction(
			"Choose a weapon to continue."
		)

func equip_nearest_weapon() -> void:
	if not is_instance_valid(nearest_pedestal):
		return

	if not nearest_pedestal.is_player_near(
		dungeon_player.global_position
	):
		return

	var weapon: WeaponData = (
		nearest_pedestal.get_weapon()
	)

	if weapon == null:
		return

	dungeon_player.equip_weapon(weapon)

func on_weapon_equipped(weapon: WeaponData) -> void:
	hud.update_weapon(weapon)

	for pedestal in weapon_pedestals.get_children():
		pedestal.set_selected(
			pedestal.get_weapon() == weapon
		)

	if dungeon_generator.is_start_room():
		encounter_state = EncounterState.UNLOCKED
		dungeon_generator.unlock_exit()
		update_weapon_interaction()

func clear_weapon_pedestals() -> void:
	nearest_pedestal = null

	for pedestal in weapon_pedestals.get_children():
		weapon_pedestals.remove_child(pedestal)
		pedestal.queue_free()

# --------------------------------------------------
# ENEMY NAVIGATION
# --------------------------------------------------
func build_navigation_grid() -> void:
	var room: Rect2i = get_current_room()

	path_grid = AStarGrid2D.new()
	path_grid.region = room

	path_grid.cell_size = Vector2(
		dungeon_generator.tile_size,
		dungeon_generator.tile_size
	)

	path_grid.diagonal_mode = (
		AStarGrid2D.DIAGONAL_MODE_NEVER
	)

	path_grid.default_compute_heuristic = (
		AStarGrid2D.HEURISTIC_MANHATTAN
	)

	path_grid.default_estimate_heuristic = (
		AStarGrid2D.HEURISTIC_MANHATTAN
	)

	path_grid.update()

	for obstacle in dungeon_generator.obstacles:
		path_grid.fill_solid_region(
			obstacle,
			true
		)

func tile_to_world(tile: Vector2i) -> Vector2:
	var local_position: Vector2 = Vector2(
		(tile.x + 0.5) * dungeon_generator.tile_size,
		(tile.y + 0.5) * dungeon_generator.tile_size
	)

	return dungeon_generator.to_global(local_position)

func world_to_tile(world_position: Vector2) -> Vector2i:
	var local_position: Vector2 = (
		dungeon_generator.to_local(world_position)
	)

	return Vector2i(
		floori(local_position.x / dungeon_generator.tile_size),
		floori(local_position.y / dungeon_generator.tile_size)
	)

func get_spawn_tiles() -> Array[Vector2i]:
	var room: Rect2i = get_current_room()

	var available_tiles: Array[Vector2i] = []

	var player_tile: Vector2i = (
		world_to_tile(dungeon_player.global_position)
	)

	var exit_position: Vector2 = (
		dungeon_generator.to_global(
			dungeon_generator.get_exit_position()
		)
	)

	if not path_grid.is_in_boundsv(player_tile):
		return available_tiles

	if path_grid.is_point_solid(player_tile):
		return available_tiles

	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			var tile: Vector2i = Vector2i(x, y)

			if path_grid.is_point_solid(tile):
				continue

			var spawn_position: Vector2 = (
				tile_to_world(tile)
			)

			if spawn_position.distance_to(
				dungeon_player.global_position
			) < enemy_spawn_distance:
				continue

			if spawn_position.distance_to(
				exit_position
			) < 50.0:
				continue

			var path: Array[Vector2i] = (
				path_grid.get_id_path(
					player_tile,
					tile
				)
			)

			if path.is_empty():
				continue

			available_tiles.append(tile)

	available_tiles.shuffle()

	return available_tiles

# --------------------------------------------------
# RANDOMIZED ENEMY SPAWNING
# --------------------------------------------------
func get_random_enemy_type() -> int:

	var standard: int = maxi(standard_weight, 0)
	var fast: int = maxi(fast_weight, 0)
	var heavy: int = maxi(heavy_weight, 0)
	var ranged: int = maxi(ranged_weight, 0)

	var total_weight: int = (
		standard + fast + heavy + ranged
	)

	if total_weight <= 0:
		return 0  # STANDARD

	var roll: int = randi_range(1, total_weight)

	if roll <= standard:
		return 0  # STANDARD

	if roll <= standard + fast:
		return 1  # FAST

	if roll <= standard + fast + heavy:
		return 2  # HEAVY

	return 3  # RANGED
	
func spawn_enemies() -> void:
	if not dungeon_generator.is_combat_room():
		return

	var requested_count: int = randi_range(
		mini(min_enemies, max_enemies),
		maxi(min_enemies, max_enemies)
	)

	requested_count = maxi(requested_count, 0)

	var available_tiles: Array[Vector2i] = (
		get_spawn_tiles()
	)

	var used_positions: Array[Vector2] = []

	remaining_enemies = 0

	var standard_count: int = 0
	var fast_count: int = 0
	var heavy_count: int = 0
	var ranged_count: int = 0

	for tile in available_tiles:
		if remaining_enemies >= requested_count:
			break

		var spawn_position: Vector2 = (
			tile_to_world(tile)
		)

		var too_close: bool = false

		for used_position in used_positions:
			if spawn_position.distance_to(
				used_position
			) < enemy_spacing:
				too_close = true
				break

		if too_close:
			continue

		var chosen_type: int = get_random_enemy_type()

		create_enemy(tile, chosen_type)

		match chosen_type:
			0:
				standard_count += 1
			1:
				fast_count += 1
			2:
				heavy_count += 1
			3:
				ranged_count += 1

		used_positions.append(spawn_position)
		remaining_enemies += 1

	print(
		"Room ",
		dungeon_generator.current_room_index + 1,
		": Spawned ",
		remaining_enemies,
		" enemies."
	)

	print(
		"Enemy types - Standard: ",
		standard_count,
		", Fast: ",
		fast_count,
		", Heavy: ",
		heavy_count,
		", Ranged: ",
		ranged_count
	)

	if remaining_enemies == 0:
		push_warning("No valid enemy spawn positions.")
		complete_encounter()

# Instantiate and configure the chosen enemy type.
func create_enemy(
	tile: Vector2i,
	chosen_type: int ) -> void:
	var enemy = ENEMY_SCENE.instantiate()

	# Assign type BEFORE add_child() calls _ready().
	enemy.enemy_type = chosen_type

	enemy.position = (
		enemies.to_local(tile_to_world(tile))
	)

	enemy.movement_enabled = enemy_movement_enabled

	enemy.setup(
		dungeon_player,
		dungeon_generator,
		path_grid,
		tile,
		dungeon_generator.tile_size
	)

	enemy.enemy_defeated.connect(
		on_enemy_defeated
	)

	enemies.add_child(enemy)

	print(
		"Enemy spawned: ",
		enemy.EnemyType.keys()[chosen_type],
		" at tile ",
		tile,
		" | HP: ",
		enemy.max_health,
		" | Damage: ",
		enemy.attack_damage
	)

func on_enemy_defeated() -> void:
	if encounter_state != EncounterState.LOCKED:
		return

	remaining_enemies = maxi(
		remaining_enemies - 1,
		0
	)

	print("Enemies remaining: ", remaining_enemies)

	if remaining_enemies == 0:
		complete_encounter()

func complete_encounter() -> void:
	if encounter_state != EncounterState.LOCKED:
		return

	encounter_state = EncounterState.UNLOCKED

	dungeon_generator.unlock_exit()

	print("Combat encounter completed!")

func clear_enemies() -> void:
	for enemy in enemies.get_children():
		enemy.set_physics_process(false)

		if enemy.is_in_group("dungeon_enemies"):
			enemy.remove_from_group(
				"dungeon_enemies"
			)

		enemies.remove_child(enemy)
		enemy.queue_free()

	remaining_enemies = 0
	path_grid = null

# --------------------------------------------------
# REWARD ROOM SYSTEM
# --------------------------------------------------
func spawn_reward_pedestals() -> void:
	clear_reward_pedestals()

	var reward_types: Array[int] = [
		RewardPedestal.RewardType.HEAL,
		RewardPedestal.RewardType.DAMAGE,
		RewardPedestal.RewardType.MAX_HEALTH
	]

	var center: Vector2 = (
		dungeon_generator.get_current_room_center()
	)

	var room: Rect2i = get_current_room()

	var room_width: float = (
		room.size.x * dungeon_generator.tile_size
	)

	var room_height: float = (
		room.size.y * dungeon_generator.tile_size
	)

	var spacing: float = minf(
		110.0,
		(room_width - 100.0) / 2.0
	)

	var vertical_offset: float = minf(
		90.0,
		room_height / 2.0 - 45.0
	)

	for i in range(reward_types.size()):
		var pedestal: RewardPedestal = (
			REWARD_PEDESTAL_SCENE.instantiate()
		)

		var offset_x: float = (
			(i - 1) * spacing
		)

		var local_position: Vector2 = (
			center + Vector2(offset_x, -vertical_offset)
		)

		var world_position: Vector2 = (
			dungeon_generator.to_global(
				local_position
			)
		)

		pedestal.position = (
			reward_pedestals.to_local(
				world_position
			)
		)

		pedestal.setup(reward_types[i])
		reward_pedestals.add_child(pedestal)

	print(
		"Reward pedestals spawned: ",
		reward_pedestals.get_child_count()
	)

func update_reward_interaction() -> void:
	nearest_reward_pedestal = null

	if reward_selected:
		hud.show_interaction(
			"Reward collected. Exit unlocked."
		)
		return

	var nearest_distance: float = INF

	for child in reward_pedestals.get_children():
		var pedestal: RewardPedestal = child

		if not pedestal.is_player_near(
			dungeon_player.global_position
		):
			continue

		var distance: float = (
			pedestal.global_position.distance_to(
				dungeon_player.global_position
			)
		)

		if distance < nearest_distance:
			nearest_distance = distance
			nearest_reward_pedestal = pedestal

	for child in reward_pedestals.get_children():
		var pedestal: RewardPedestal = child

		pedestal.set_highlighted(
			pedestal == nearest_reward_pedestal
		)

	if is_instance_valid(nearest_reward_pedestal):
		hud.show_interaction(
			"Press E: " +
			nearest_reward_pedestal.get_reward_name()
		)
	else:
		hud.show_interaction(
			"Choose one reward to continue."
		)

func select_nearest_reward() -> void:
	if reward_selected:
		return

	if not is_instance_valid(nearest_reward_pedestal):
		return

	var pedestal: RewardPedestal = (
		nearest_reward_pedestal
	)

	if not pedestal.is_player_near(
		dungeon_player.global_position
	):
		return

	var reward_name: String = (
		pedestal.get_reward_name()
	)

	match pedestal.reward_type:
		RewardPedestal.RewardType.HEAL:
			dungeon_player.heal(25)
			RunData.record_healing_reward()

		RewardPedestal.RewardType.DAMAGE:
			RunData.add_damage_upgrade()

		RewardPedestal.RewardType.MAX_HEALTH:
			# Maximum HP increases without healing.
			dungeon_player.increase_max_health(20)
			RunData.add_max_health_upgrade(20)

	reward_selected = true

	for child in reward_pedestals.get_children():
		var other_pedestal: RewardPedestal = child

		if other_pedestal == pedestal:
			other_pedestal.set_claimed(true)
		else:
			other_pedestal.set_unavailable(true)

	nearest_reward_pedestal = null

	encounter_state = EncounterState.UNLOCKED
	dungeon_generator.unlock_exit()

	hud.update_upgrades()

	hud.show_interaction(
		"Collected: " + reward_name +
		" | Exit unlocked."
	)

	print("Reward selected: ", reward_name)

	print(
		"Total rewards collected: ",
		RunData.rewards_collected
	)

	print(
		"Current HP: ",
		dungeon_player.health,
		"/",
		dungeon_player.max_health
	)

	print(
		"Current weapon damage: ",
		dungeon_player.get_attack_damage()
	)

func clear_reward_pedestals() -> void:
	nearest_reward_pedestal = null

	for pedestal in reward_pedestals.get_children():
		reward_pedestals.remove_child(pedestal)
		pedestal.queue_free()

# --------------------------------------------------
# PLAYER DEFEAT AND DUNGEON COMPLETION
# --------------------------------------------------
func on_player_defeated() -> void:
	encounter_state = EncounterState.FAILED
	transitioning = false

	for enemy in enemies.get_children():
		enemy.set_physics_process(false)

	hud.show_defeat()

	print("Dungeon run failed.")
	RunData.save_health(0)
	# The defeat screen remains visible for now.
	# A restart button can call GameManager.player_lost().

func complete_dungeon() -> void:
	if encounter_state == EncounterState.COMPLETE:
		return

	# The final reward must be selected first.
	if not reward_selected:
		return

	encounter_state = EncounterState.COMPLETE

	clear_enemies()
	clear_weapon_pedestals()
	clear_reward_pedestals()

	hud.hide_interaction()

	dungeon_player.set_physics_process(false)

	print("Dungeon completed!")

	print(
		"Weapon entering arena: ",
		RunData.get_weapon_id()
	)

	print(
		"Weapon damage entering arena: ",
		RunData.get_weapon_damage()
	)

	print(
		"Maximum HP bonus entering arena: +",
		RunData.bonus_max_health
	)

	print(
		"Total rewards collected: ",
		RunData.rewards_collected
	)


	# Start the arena after completing the final reward room.
	# Deferred so we do not replace the current scene while
	# processing the dungeon exit.
	call_deferred("transition_to_arena")
	
	
	RunData.save_dungeon_player(dungeon_player)

	call_deferred("go_to_arena")

func go_to_arena() -> void:
	if encounter_state != EncounterState.COMPLETE:
		return

	GameManager.enter_arena()

func transition_to_arena() -> void:
	if encounter_state != EncounterState.COMPLETE:
		return

	if not RunData.has_weapon():
		push_error("Cannot enter arena without a weapon.")
		return

	DungeonToArena.enter_arena(get_tree())

# --------------------------------------------------
# FIREBOLT PROJECTILES
# --------------------------------------------------
func on_firebolt_cast(
	start_position: Vector2,
	direction: Vector2,
	damage: int,
	max_range: float ) -> void:
	var firebolt = FIREBOLT_SCENE.instantiate()

	add_child(firebolt)

	firebolt.setup(
		start_position,
		direction,
		damage,
		max_range
	)

	print("Firebolt projectile spawned.")
	
func apply_difficulty_settings() -> void:
	match GameManager.current_dungeon:

		1:
			min_enemies = 2
			max_enemies = 3

			standard_weight = 50
			fast_weight = 25
			heavy_weight = 15
			ranged_weight = 10

		2:
			min_enemies = 3
			max_enemies = 4

			standard_weight = 35
			fast_weight = 30
			heavy_weight = 20
			ranged_weight = 15

		3:
			min_enemies = 4
			max_enemies = 5

			standard_weight = 25
			fast_weight = 30
			heavy_weight = 25
			ranged_weight = 20

	print(
		"Dungeon ",
		GameManager.current_dungeon,
		" | Difficulty: ",
		GameManager.get_difficulty_name()
	)
