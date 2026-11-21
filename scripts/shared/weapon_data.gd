
extends Resource
class_name WeaponData

# The Arena Below - Shared Weapon Data
# Purpose: Stores weapon information for both
# the dungeon and arena combat systems.
#
# References:
# https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html
# https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_exports.html


enum WeaponType {
	SWORD,
	BATTLE_AXE,
	SPEAR,
	FISTS
}


# General weapon information.
@export var weapon_id: String = "sword"
@export var weapon_name: String = "Sword"

@export var weapon_type: WeaponType = WeaponType.SWORD

@export_multiline var description: String = ""


# Dungeon combat settings.
@export_group("Dungeon Combat")

@export var damage: int = 1

@export var attack_range: float = 40.0

@export var attack_cooldown: float = 0.4

@export_range(1.0, 360.0) var attack_arc: float = 145.0


# Temporary gray-box appearance.
@export_group("Appearance")

@export var weapon_color: Color = Color.WHITE


# Return half of the attack angle in radians.
func get_half_attack_angle() -> float:

	return deg_to_rad(attack_arc / 2.0)


# Return the minimum dot product needed for a hit.
func get_attack_dot_threshold() -> float:

	return cos(get_half_attack_angle())
