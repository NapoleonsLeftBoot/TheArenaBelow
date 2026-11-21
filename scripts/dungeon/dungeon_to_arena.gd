
extends Node
class_name DungeonToArena

# Loads the existing arena and passes the dungeon weapon
# to the arena player before the new scene starts.

const ARENA_SCENE: PackedScene = preload(
    "res://scenes/arena/level.tscn"
)


static func get_arena_weapon() -> WeaponTypes.Type:
	match RunData.get_weapon_id():
		"fists":
			return WeaponTypes.Type.FISTS

		"battle_axe":
			# Temporary mapping until the axe moveset exists.
			return WeaponTypes.Type.HAMMER

		"sword", "spear":
			# Temporary mapping until these movesets exist.
			return WeaponTypes.Type.FISTS

		_:
			push_warning(
                "Unknown dungeon weapon. Using Fists."
			)
			return WeaponTypes.Type.FISTS


static func enter_arena(tree: SceneTree) -> void:
	var arena: Node = ARENA_SCENE.instantiate()

	if arena == null:
		push_error("Could not instantiate arena.")
		return

	var arena_player: Player = arena.get_node_or_null(
        "Player"
	) as Player

	if arena_player == null:
		push_error("Arena Player node not found.")
		arena.free()
		return

	# Set the moveset before the arena player runs _ready().
	arena_player.set_weapon(get_arena_weapon())

	var previous_scene: Node = tree.current_scene

	# Match the scene replacement approach used by the
	# existing weapon_test_pass.gd prototype.
	tree.root.add_child(arena)
	tree.current_scene = arena

	if is_instance_valid(previous_scene):
		previous_scene.queue_free()

	print("Transitioned from dungeon to arena.")
	print("Dungeon weapon: ", RunData.get_weapon_id())
	print("Arena moveset: ", get_arena_weapon())
