extends CharacterBody2D

# The Arena Below - Dungeon Player
# Movement, dodge, melee weapons, health, Firebolt, Arcane Shield and mana.
# Godot docs: https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html

signal attack_performed
signal health_changed(current_health: int, maximum_health: int)
signal player_defeated
signal weapon_equipped(weapon: WeaponData)
signal max_health_changed(new_max_health: int)
signal firebolt_cast(start_position: Vector2, direction: Vector2, damage: int, max_range: float)
signal shield_started
signal shield_ended
signal magic_cooldowns_changed(firebolt_remaining: float, shield_remaining: float)
signal mana_changed(current_mana: float, maximum_mana: float)

@export_group("Movement")
@export var movement_speed: float = 120.0
@export var player_size: float = 14.0
@export_group("Health")
@export var max_health: int = 100
@export var damage_immunity: float = 0.5
@export_group("Dodging")
@export var dodge_distance: float = 90.0
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 1.0
@export_group("Magic")
@export var max_mana: float = 100.0
@export var mana_regeneration: float = 5.0
@export var firebolt_mana_cost: float = 25.0
@export var shield_mana_cost: float = 40.0
@export var firebolt_damage: int = 2
@export var firebolt_range: float = 180.0
@export var firebolt_cooldown: float = 1.5
@export var shield_duration: float = 2.0
@export var shield_cooldown: float = 8.0

var health: int
var defeated: bool = false
var facing_direction: Vector2 = Vector2.RIGHT
var current_weapon: WeaponData = null
var attack_timer: float = 0.0
var immunity_timer: float = 0.0
var attack_flash_timer: float = 0.0
var damage_flash_timer: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var is_dodging: bool = false
var dodge_direction: Vector2 = Vector2.RIGHT
var dodge_time_remaining: float = 0.0
var dodge_cooldown_remaining: float = 0.0
var dodge_key_was_pressed: bool = false
var mana: float = 100.0
var firebolt_cooldown_remaining: float = 0.0
var shield_cooldown_remaining: float = 0.0
var shield_time_remaining: float = 0.0
var shield_active: bool = false

func _ready() -> void:
	z_index = 10
	health = max_health
	mana = maxf(max_mana, 0.0)
	current_weapon = null
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	health_changed.emit(health, max_health)
	mana_changed.emit(mana, max_mana)

func _physics_process(delta: float) -> void:
	if defeated:
		velocity = Vector2.ZERO
		return
	update_timers(delta)
	update_dodge_cooldown(delta)
	update_magic(delta)
	var dodge_key_pressed: bool = Input.is_key_pressed(KEY_SHIFT)
	var dodge_just_pressed: bool = dodge_key_pressed and not dodge_key_was_pressed
	dodge_key_was_pressed = dodge_key_pressed
	if is_dodging:
		update_dodge(delta)
	else:
		if dodge_just_pressed:
			start_dodge()
		if not is_dodging:
			handle_movement()
			handle_attack()
			handle_magic_input()
	queue_redraw()

func update_timers(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	immunity_timer = maxf(immunity_timer - delta, 0.0)
	attack_flash_timer = maxf(attack_flash_timer - delta, 0.0)
	damage_flash_timer = maxf(damage_flash_timer - delta, 0.0)

func get_movement_direction() -> Vector2:
	var direction: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direction.x += 1.0
	return direction.normalized()

func handle_movement() -> void:
	var direction: Vector2 = get_movement_direction()
	if direction != Vector2.ZERO:
		facing_direction = direction
	velocity = direction * movement_speed
	move_and_slide()

func update_dodge_cooldown(delta: float) -> void:
	dodge_cooldown_remaining = maxf(dodge_cooldown_remaining - delta, 0.0)

func start_dodge() -> void:
	if defeated or is_dodging or dodge_cooldown_remaining > 0.0 or dodge_duration <= 0.0:
		return
	var input_direction: Vector2 = get_movement_direction()
	dodge_direction = facing_direction.normalized() if input_direction == Vector2.ZERO else input_direction
	if dodge_direction == Vector2.ZERO:
		dodge_direction = Vector2.RIGHT
	facing_direction = dodge_direction
	is_dodging = true
	dodge_time_remaining = dodge_duration
	dodge_cooldown_remaining = dodge_cooldown
	print("Player dodged.")

func update_dodge(delta: float) -> void:
	if not is_dodging:
		return
	velocity = dodge_direction * (dodge_distance / dodge_duration)
	move_and_slide()
	dodge_time_remaining = maxf(dodge_time_remaining - delta, 0.0)
	if dodge_time_remaining <= 0.0:
		finish_dodge()

func finish_dodge() -> void:
	is_dodging = false
	dodge_time_remaining = 0.0
	velocity = Vector2.ZERO
	print("Dodge finished.")

func equip_weapon(weapon: WeaponData) -> void:
	if defeated or weapon == null or current_weapon == weapon:
		return
	current_weapon = weapon
	attack_flash_timer = 0.0
	RunData.select_weapon(current_weapon)
	weapon_equipped.emit(current_weapon)
	print("Equipped weapon: ", current_weapon.weapon_name)
	print("Damage: ", current_weapon.damage, " | Range: ", current_weapon.attack_range, " | Cooldown: ", current_weapon.attack_cooldown, " | Arc: ", current_weapon.attack_arc)
	queue_redraw()

func get_current_weapon() -> WeaponData:
	return current_weapon

func has_weapon() -> bool:
	return current_weapon != null

func get_attack_damage() -> int:
	if current_weapon == null:
		return 0
	return current_weapon.damage + RunData.bonus_damage

func handle_attack() -> void:
	if not has_weapon():
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_key_pressed(KEY_SPACE):
		attack()

func attack() -> void:
	if defeated or is_dodging or not has_weapon() or attack_timer > 0.0:
		return
	attack_timer = current_weapon.attack_cooldown
	attack_flash_timer = 0.15
	attack_direction = facing_direction
	attack_performed.emit()
	print("Attacking with ", current_weapon.weapon_name)
	var enemy_list: Array = get_tree().get_nodes_in_group("dungeon_enemies")
	for enemy in enemy_list:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		if can_hit_enemy(enemy):
			enemy.take_damage(get_attack_damage())

func can_hit_enemy(enemy: Node2D) -> bool:
	var to_enemy: Vector2 = enemy.global_position - global_position
	var distance: float = to_enemy.length()
	if distance > current_weapon.attack_range:
		return false
	if distance > 0.01:
		var direction_to_enemy: Vector2 = to_enemy.normalized()
		var dot_product: float = attack_direction.dot(direction_to_enemy)
		var minimum_dot: float = current_weapon.get_attack_dot_threshold()
		if dot_product < minimum_dot - 0.0001:
			return false
		if not has_clear_attack_path(enemy):
			return false
	return true

func has_clear_attack_path(enemy: Node2D) -> bool:
	var query = PhysicsRayQueryParameters2D.create(global_position, enemy.global_position)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return result.is_empty()

# Mana regenerates continuously, including while dodging or shielded.
func update_magic(delta: float) -> void:
	firebolt_cooldown_remaining = maxf(firebolt_cooldown_remaining - delta, 0.0)
	shield_cooldown_remaining = maxf(shield_cooldown_remaining - delta, 0.0)
	if shield_active:
		shield_time_remaining = maxf(shield_time_remaining - delta, 0.0)
		if shield_time_remaining <= 0.0:
			deactivate_shield()
	if mana < max_mana:
		set_mana(mana + maxf(mana_regeneration, 0.0) * delta)
	magic_cooldowns_changed.emit(firebolt_cooldown_remaining, shield_cooldown_remaining)

func set_mana(amount: float) -> void:
	var new_mana: float = clampf(amount, 0.0, maxf(max_mana, 0.0))
	if is_equal_approx(new_mana, mana):
		return
	mana = new_mana
	mana_changed.emit(mana, max_mana)

func has_enough_mana(cost: float) -> bool:
	return mana + 0.0001 >= cost

func handle_magic_input() -> void:
	if Input.is_action_just_pressed("cast_firebolt"):
		cast_firebolt()
	if Input.is_action_just_pressed("cast_shield"):
		cast_shield()

func cast_firebolt() -> void:
	if defeated or is_dodging or firebolt_cooldown_remaining > 0.0:
		return
	if not has_enough_mana(firebolt_mana_cost):
		print("Not enough mana for Firebolt.")
		return
	set_mana(mana - firebolt_mana_cost)
	firebolt_cooldown_remaining = firebolt_cooldown
	var direction: Vector2 = facing_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	firebolt_cast.emit(global_position, direction, firebolt_damage, firebolt_range)
	print("Firebolt cast! Mana: ", snappedf(mana, 0.1))

func cast_shield() -> void:
	if defeated or is_dodging or shield_active or shield_cooldown_remaining > 0.0:
		return
	if not has_enough_mana(shield_mana_cost):
		print("Not enough mana for Arcane Shield.")
		return
	set_mana(mana - shield_mana_cost)
	shield_active = true
	shield_time_remaining = shield_duration
	shield_cooldown_remaining = shield_cooldown
	shield_started.emit()
	queue_redraw()
	print("Arcane Shield activated! Mana: ", snappedf(mana, 0.1))

func deactivate_shield() -> void:
	if not shield_active:
		return
	shield_active = false
	shield_time_remaining = 0.0
	shield_ended.emit()
	queue_redraw()
	print("Arcane Shield expired.")

func take_damage(amount: int) -> void:
	if defeated or is_dodging or shield_active or amount <= 0 or immunity_timer > 0.0:
		return
	health = maxi(health - amount, 0)
	immunity_timer = damage_immunity
	damage_flash_timer = 0.2
	print("Player health: ", health, "/", max_health)
	health_changed.emit(health, max_health)
	queue_redraw()
	if health <= 0:
		die()

func heal(amount: int) -> void:
	if defeated or amount <= 0:
		return
	health = mini(health + amount, max_health)
	health_changed.emit(health, max_health)
	print("Player healed: ", health, "/", max_health)

func increase_max_health(amount: int) -> void:
	if defeated or amount <= 0:
		return
	max_health += amount
	health_changed.emit(health, max_health)
	max_health_changed.emit(max_health)
	print("Maximum health increased to ", max_health, ". Current health remains ", health)

func die() -> void:
	if defeated:
		return
	defeated = true
	velocity = Vector2.ZERO
	if shield_active:
		deactivate_shield()
	print("Player defeated!")
	queue_redraw()
	player_defeated.emit()

func _draw() -> void:
	var half_size: float = player_size / 2.0
	var body_color: Color = Color(0.2, 0.6, 1.0)
	if damage_flash_timer > 0.0:
		body_color = Color.WHITE
	if defeated:
		body_color = Color(0.3, 0.3, 0.3)
	draw_rect(Rect2(-half_size, -half_size, player_size, player_size), body_color)
	if shield_active:
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 40, Color(0.2, 0.75, 1.0, 0.9), 3.0)
	if defeated:
		return
	draw_line(Vector2.ZERO, facing_direction * 12.0, Color.WHITE, 2.0)
	if has_weapon():
		draw_equipped_weapon()
	if attack_flash_timer > 0.0:
		draw_attack_effect()

func draw_equipped_weapon() -> void:
	var side_direction: Vector2 = facing_direction.orthogonal()
	var weapon_start: Vector2 = side_direction * 9.0
	var weapon_color: Color = current_weapon.weapon_color
	match current_weapon.weapon_type:
		WeaponData.WeaponType.SWORD:
			var sword_end: Vector2 = weapon_start + facing_direction * 20.0
			draw_line(weapon_start, sword_end, weapon_color, 3.0)
			draw_line(weapon_start - side_direction * 4.0, weapon_start + side_direction * 4.0, Color(0.4, 0.3, 0.2), 3.0)
		WeaponData.WeaponType.BATTLE_AXE:
			var axe_end: Vector2 = weapon_start + facing_direction * 20.0
			draw_line(weapon_start, axe_end, Color(0.45, 0.3, 0.15), 3.0)
			draw_line(axe_end - side_direction * 7.0, axe_end + side_direction * 7.0, weapon_color, 6.0)
		WeaponData.WeaponType.SPEAR:
			var spear_end: Vector2 = weapon_start + facing_direction * 32.0
			draw_line(weapon_start, spear_end, Color(0.45, 0.3, 0.15), 3.0)
			draw_line(spear_end, spear_end + facing_direction * 9.0, weapon_color, 4.0)
		WeaponData.WeaponType.FISTS:
			var left_fist: Vector2 = facing_direction * 9.0 - side_direction * 7.0
			var right_fist: Vector2 = facing_direction * 9.0 + side_direction * 7.0
			draw_circle(left_fist, 4.0, weapon_color)
			draw_circle(right_fist, 4.0, weapon_color)

func draw_attack_effect() -> void:
	if not has_weapon():
		return
	var angle: float = attack_direction.angle()
	var half_angle: float = current_weapon.get_half_attack_angle()
	draw_arc(Vector2.ZERO, current_weapon.attack_range, angle - half_angle, angle + half_angle, 32, current_weapon.weapon_color, 3.0)
