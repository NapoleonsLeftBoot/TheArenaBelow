
extends Node

# The Arena Below - Shared Run Data
# Stores the weapon and upgrades for the current run.
# The arena will read these values later.

signal weapon_changed(weapon: WeaponData)
signal upgrades_changed

var selected_weapon: WeaponData = null

var bonus_damage: int = 0
var bonus_max_health: int = 0

var rewards_collected: int = 0


func select_weapon(weapon: WeaponData) -> void:
	if weapon == null:
		return

	selected_weapon = weapon
	weapon_changed.emit(selected_weapon)

	print("Run weapon selected: ", weapon.weapon_name)


func get_weapon() -> WeaponData:
	return selected_weapon


func get_weapon_id() -> String:
	if selected_weapon == null:
		return ""

	return selected_weapon.weapon_id


func has_weapon() -> bool:
	return selected_weapon != null


func get_weapon_damage() -> int:
	if selected_weapon == null:
		return 0

	return selected_weapon.damage + bonus_damage


func add_damage_upgrade() -> void:
	bonus_damage += 1
	rewards_collected += 1

	upgrades_changed.emit()

	print("Bonus weapon damage: +", bonus_damage)


func add_max_health_upgrade(amount: int) -> void:
	if amount <= 0:
		return

	bonus_max_health += amount
	rewards_collected += 1

	upgrades_changed.emit()

	print("Bonus maximum health: +", bonus_max_health)


func record_healing_reward() -> void:
	rewards_collected += 1
	upgrades_changed.emit()


func reset_run() -> void:
	selected_weapon = null

	bonus_damage = 0
	bonus_max_health = 0
	rewards_collected = 0

	upgrades_changed.emit()

	print("Run data reset.")
