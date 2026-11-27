
extends Node

# Controls the full dungeon -> arena -> dungeon loop.

const DUNGEON_SCENE = preload(
    "res://scenes/dungeon/dungeon_level.tscn"
)

const ARENA_SCENE = preload(
    "res://scenes/arena/level.tscn"
)

var run_started: bool = false
var current_dungeon: int = 1
var in_arena: bool = false
var run_finished: bool = false


func start_new_run() -> void:
	RunData.reset_run()
	current_dungeon = 1
	in_arena = false
	run_finished = false
	run_started = true

	print("Starting Dungeon 1 - Easy")


func get_difficulty_name() -> String:
	match current_dungeon:
		1:
			return "Easy"
		2:
			return "Medium"
		3:
			return "Hard"

	return "Unknown"


func enter_arena() -> void:
	if in_arena or run_finished:
		return

	if not RunData.has_weapon():
		push_error("No weapon selected.")
		return

	var arena: Node = ARENA_SCENE.instantiate()
	var fighter: Player = arena.get_node_or_null(
        "Player"
	) as Player

	if fighter == null:
		push_error("Arena player not found.")
		arena.free()
		return

	# The arena currently supports Fists and Hammer.
	match RunData.get_weapon_id():
		"battle_axe":
			fighter.set_weapon(WeaponTypes.Type.HAMMER)
		_:
			fighter.set_weapon(WeaponTypes.Type.FISTS)

	in_arena = true

	# Arena _ready() initializes its player at full HP.
	# Restore the saved health after that initialization.
	var old_scene: Node = get_tree().current_scene

	get_tree().root.add_child(arena)
	get_tree().current_scene = arena

	fighter.max_health = RunData.get_max_health()
	fighter.health = RunData.current_health

	var arena_hud: Node = arena.get_node_or_null("Hud")
	if arena_hud != null:
		arena_hud.sync_health_bars()

	if is_instance_valid(old_scene):
		old_scene.queue_free()

	print("Entered Arena ", current_dungeon)
	print("Health: ", RunData.current_health,
		"/", RunData.get_max_health())


func arena_won(remaining_health: int) -> void:
	if not in_arena or run_finished:
		return

	RunData.save_health(remaining_health)
	in_arena = false

	if current_dungeon >= 3:
		run_finished = true
		print("VICTORY! The player escaped!")
		return

	current_dungeon += 1

	print("Entering Dungeon ", current_dungeon)
	print("Difficulty: ", get_difficulty_name())

	get_tree().change_scene_to_packed(DUNGEON_SCENE)


func player_lost() -> void:
	print("Run failed in Dungeon/Arena ",
		current_dungeon)

	# Start a completely new run.
	start_new_run()
	get_tree().change_scene_to_packed(DUNGEON_SCENE)
