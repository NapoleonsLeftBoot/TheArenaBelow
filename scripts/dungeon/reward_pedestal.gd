
extends Node2D
class_name RewardPedestal

# The Arena Below - Reward Pedestal
# Draws a reward and allows distance-based interaction.
#
# Godot documentation:
# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html


enum RewardType {
	HEAL,
	DAMAGE,
	MAX_HEALTH
}


@export var reward_type: RewardType = RewardType.HEAL
@export var interaction_range: float = 45.0

var highlighted: bool = false
var claimed: bool = false
var unavailable: bool = false


func setup(type: RewardType) -> void:
	reward_type = type
	queue_redraw()


func get_reward_name() -> String:
	match reward_type:
		RewardType.HEAL:
			return "Heal 25 HP"
		RewardType.DAMAGE:
			return "Weapon Damage +1"
		RewardType.MAX_HEALTH:
			return "Maximum HP +20"

	return "Unknown Reward"


func get_reward_color() -> Color:
	match reward_type:
		RewardType.HEAL:
			return Color(0.95, 0.3, 0.35)
		RewardType.DAMAGE:
			return Color(0.95, 0.7, 0.2)
		RewardType.MAX_HEALTH:
			return Color(0.3, 0.65, 1.0)

	return Color.WHITE


func is_player_near(player_position: Vector2) -> bool:
	if claimed or unavailable:
		return false

	return global_position.distance_to(
		player_position
	) <= interaction_range


func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return

	highlighted = value
	queue_redraw()


func set_claimed(value: bool) -> void:
	claimed = value
	highlighted = false
	queue_redraw()


func set_unavailable(value: bool) -> void:
	unavailable = value
	highlighted = false
	queue_redraw()


func _draw() -> void:
	var size: float = 48.0
	var half_size: float = size / 2.0

	var pedestal_rect: Rect2 = Rect2(
		-half_size,
		-half_size,
		size,
		size
	)

	var reward_color: Color = get_reward_color()

	if unavailable:
		reward_color = Color(0.35, 0.35, 0.35)

	if claimed:
		draw_rect(
			pedestal_rect.grow(4.0),
			Color(0.2, 0.9, 0.35)
		)

	if highlighted:
		draw_rect(
			pedestal_rect.grow(5.0),
			Color(1.0, 0.85, 0.2),
			false,
			2.0
		)

		draw_arc(
			Vector2.ZERO,
			interaction_range,
			0.0,
			TAU,
			40,
			Color(1.0, 0.85, 0.2),
			1.0
		)

	draw_rect(
		pedestal_rect,
		Color(0.28, 0.28, 0.28)
	)

	draw_reward_icon(reward_color)
	draw_reward_label()


func draw_reward_icon(color: Color) -> void:
	match reward_type:
		RewardType.HEAL:
			# Red cross.
			draw_rect(
				Rect2(-5, -16, 10, 32),
				color
			)
			draw_rect(
				Rect2(-16, -5, 32, 10),
				color
			)

		RewardType.DAMAGE:
			# Crossed weapons.
			draw_line(
				Vector2(-13, 13),
				Vector2(13, -13),
				color,
				4.0
			)
			draw_line(
				Vector2(13, 13),
				Vector2(-13, -13),
				color,
				4.0
			)

		RewardType.MAX_HEALTH:
			# Shield.
			var points: PackedVector2Array = PackedVector2Array([
				Vector2(-15, -14),
				Vector2(15, -14),
				Vector2(13, 5),
				Vector2(0, 18),
				Vector2(-13, 5)
			])

			draw_colored_polygon(points, color)


func draw_reward_label() -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size: int = 12

	var label_text: String = get_reward_name()

	if claimed:
		label_text = "SELECTED"
	elif unavailable:
		label_text = "UNAVAILABLE"

	var text_width: float = font.get_string_size(
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x

	draw_string(
		font,
		Vector2(-text_width / 2.0, 43.0),
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(0.1, 0.1, 0.1)
	)
