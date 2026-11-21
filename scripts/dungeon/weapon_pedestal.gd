
extends Node2D

# The Arena Below - Weapon Pedestal
# Purpose: Displays a weapon that the player
# can select in the starting room.
#
# References:
# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html
# https://docs.godotengine.org/en/stable/classes/class_vector2.html


@export var weapon: WeaponData

@export var pedestal_size: float = 44.0
@export var interaction_range: float = 40.0

var highlighted: bool = false
var selected: bool = false


func _ready() -> void:

	z_index = 5

	queue_redraw()


# Assign a weapon to this pedestal.
func setup(new_weapon: WeaponData) -> void:

	weapon = new_weapon

	queue_redraw()


# Check whether the player is close enough.
func is_player_near(player_position: Vector2) -> bool:

	return global_position.distance_to(
		player_position
	) <= interaction_range


# Highlight the pedestal when approached.
func set_highlighted(value: bool) -> void:

	if highlighted == value:
		return

	highlighted = value

	queue_redraw()


# Show whether this weapon is currently equipped.
func set_selected(value: bool) -> void:

	if selected == value:
		return

	selected = value

	queue_redraw()


# Return the pedestal's weapon resource.
func get_weapon() -> WeaponData:

	return weapon


# Draw the pedestal and weapon.
func _draw() -> void:

	if weapon == null:
		return

	var half_size: float = pedestal_size / 2.0

	var pedestal_rect: Rect2 = Rect2(
		-half_size,
		-half_size,
		pedestal_size,
		pedestal_size
	)

	var pedestal_color: Color = Color(
		0.3,
		0.3,
		0.3
	)

	# Green border indicates equipped weapon.
	if selected:

		draw_rect(
			pedestal_rect.grow(3.0),
			Color(0.2, 0.8, 0.3)
		)

	# Yellow border indicates interaction range.
	if highlighted:

		draw_rect(
			pedestal_rect.grow(5.0),
			Color(1.0, 0.8, 0.2),
			false,
			2.0
		)

		draw_arc(
			Vector2.ZERO,
			interaction_range,
			0.0,
			TAU,
			40,
			Color(1.0, 0.8, 0.2),
			1.0
		)

	draw_rect(
		pedestal_rect,
		pedestal_color
	)

	draw_weapon()

	draw_weapon_name()


# Draw a temporary weapon icon.
func draw_weapon() -> void:

	var weapon_color: Color = weapon.weapon_color

	var handle_color: Color = Color(
		0.55,
		0.35,
		0.2
	)

	match weapon.weapon_type:

		WeaponData.WeaponType.SWORD:

			draw_line(
				Vector2(-12, 12),
				Vector2(12, -12),
				weapon_color,
				4.0
			)

			draw_line(
				Vector2(-14, 2),
				Vector2(-2, 14),
				handle_color,
				4.0
			)

		WeaponData.WeaponType.BATTLE_AXE:

			draw_line(
				Vector2(-10, 14),
				Vector2(8, -12),
				handle_color,
				4.0
			)

			draw_line(
				Vector2(2, -15),
				Vector2(15, -3),
				weapon_color,
				9.0
			)

		WeaponData.WeaponType.SPEAR:

			draw_line(
				Vector2(-15, 15),
				Vector2(10, -10),
				handle_color,
				3.0
			)

			draw_line(
				Vector2(10, -10),
				Vector2(17, -17),
				weapon_color,
				5.0
			)

		WeaponData.WeaponType.FISTS:

			draw_circle(
				Vector2(-9, 0),
				8.0,
				weapon_color
			)

			draw_circle(
				Vector2(9, 0),
				8.0,
				weapon_color
			)


# Draw the name underneath the pedestal.
func draw_weapon_name() -> void:

	var font: Font = ThemeDB.fallback_font

	var font_size: int = 12

	var display_name: String = weapon.weapon_name

	if selected:

		display_name += " [Equipped]"

	var text_width: float = font.get_string_size(
		display_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x

	draw_string(
		font,
		Vector2(
			-text_width / 2.0,
			pedestal_size / 2.0 + 16.0
		),
		display_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(0.1, 0.1, 0.1)
	)
