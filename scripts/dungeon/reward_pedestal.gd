extends Node2D
class_name RewardPedestal

# The Arena Below - Reward Pedestal
# Displays rewards and handles player interaction.


enum RewardType {
	HEAL,
	DAMAGE,
	MAX_HEALTH
}


# --------------------------------------------------
# TEXTURES
# --------------------------------------------------


@export var heal_texture: Texture2D = preload(
	"res://art/dungeon/rewards/healing.png"
)

@export var damage_texture: Texture2D = preload(
	"res://art/dungeon/rewards/damage.png"
)

@export var max_health_texture: Texture2D = preload(
	"res://art/dungeon/rewards/max_health.png"
)


# --------------------------------------------------
# SETTINGS
# --------------------------------------------------


@export var reward_type: RewardType = RewardType.HEAL

@export var interaction_range: float = 55.0
@export var pedestal_size: float = 44.0

@export var pedestal_collision_size: Vector2 = Vector2(44, 44)
@export var pedestal_collision_offset: Vector2 = Vector2.ZERO

@export var float_speed: float = 2.5
@export var float_amount: float = 3.0


# --------------------------------------------------
# STATE
# --------------------------------------------------


var highlighted: bool = false
var claimed: bool = false
var unavailable: bool = false

var animation_time: float = 0.0
var float_offset: float = 0.0


# --------------------------------------------------
# INITIALIZATION
# --------------------------------------------------


func _ready() -> void:

	z_index = 0

	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	create_pedestal_collision()

	queue_redraw()

	print("NEW REWARD PEDESTAL LOADED")
	print("Reward: ", get_reward_name())


func setup(type: RewardType) -> void:

	reward_type = type

	queue_redraw()


func _process(delta: float) -> void:

	animation_time += delta

	float_offset = (
		sin(animation_time * float_speed)
		* float_amount
	)

	queue_redraw()


# --------------------------------------------------
# COLLISION
# --------------------------------------------------


func create_pedestal_collision() -> void:

	var body: StaticBody2D = StaticBody2D.new()

	body.name = "PedestalCollision"

	# Same collision layer as walls and obstacles.
	body.collision_layer = 1
	body.collision_mask = 0

	var collision: CollisionShape2D = (
		CollisionShape2D.new()
	)

	collision.name = "CollisionShape2D"

	var rectangle: RectangleShape2D = (
		RectangleShape2D.new()
	)

	rectangle.size = pedestal_collision_size

	collision.shape = rectangle
	collision.position = pedestal_collision_offset
	collision.disabled = false

	body.add_child(collision)
	add_child(body)

	print("Reward pedestal collision created: ", global_position)


# --------------------------------------------------
# REWARD INFORMATION
# --------------------------------------------------


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
			return Color("#EF4D59")

		RewardType.DAMAGE:
			return Color("#EFC04A")

		RewardType.MAX_HEALTH:
			return Color("#65CF8B")

	return Color.WHITE


func get_reward_texture() -> Texture2D:

	match reward_type:

		RewardType.HEAL:
			return heal_texture

		RewardType.DAMAGE:
			return damage_texture

		RewardType.MAX_HEALTH:
			return max_health_texture

	return null


# --------------------------------------------------
# INTERACTION
# --------------------------------------------------


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


# --------------------------------------------------
# DRAWING
# --------------------------------------------------


func _draw() -> void:

	draw_pedestal()

	if not claimed:
		draw_reward_icon()

	draw_reward_label()


# Draw the stone pedestal.
func draw_pedestal() -> void:

	var half_size: float = pedestal_size / 2.0

	var pedestal_rect: Rect2 = Rect2(
		-half_size,
		-half_size,
		pedestal_size,
		pedestal_size
	)

	# Shadow.
	draw_rect(
		Rect2(
			-half_size + 3.0,
			-half_size + 5.0,
			pedestal_size,
			pedestal_size
		),
		Color(0.0, 0.0, 0.0, 0.3)
	)

	# Main stone base.
	draw_rect(
		pedestal_rect,
		Color("#51473D")
	)

	# Raised stone surface.
	draw_rect(
		pedestal_rect.grow(-3.0),
		Color("#857564")
	)

	# Inner stone surface.
	draw_rect(
		pedestal_rect.grow(-6.0),
		Color("#A3937E")
	)

	# Darken unavailable rewards.
	if unavailable:

		draw_rect(
			pedestal_rect,
			Color(0.0, 0.0, 0.0, 0.45)
		)

	# Green border for the selected reward.
	if claimed:

		draw_rect(
			pedestal_rect.grow(2.0),
			Color("#54CF75"),
			false,
			2.0
		)

	# Gold border when the player is nearby.
	elif highlighted and not unavailable:

		draw_rect(
			pedestal_rect.grow(2.0),
			Color("#F2D15B"),
			false,
			2.0
		)


# Draw the floating reward texture.
func draw_reward_icon() -> void:

	var texture: Texture2D = get_reward_texture()

	if texture == null:
		draw_fallback_icon()
		return

	var texture_size: Vector2 = texture.get_size()

	if texture_size.x <= 0 or texture_size.y <= 0:
		draw_fallback_icon()
		return

	var icon_size: float = 32.0

	var icon_scale: float = (
		icon_size /
		maxf(texture_size.x, texture_size.y)
	)

	var draw_size: Vector2 = (
		texture_size * icon_scale
	)

	var icon_position: Vector2 = Vector2(
		-draw_size.x / 2.0,
		-draw_size.y / 2.0 - 10.0
		+ float_offset
	)

	var icon_color: Color = Color.WHITE

	if unavailable:

		icon_color = Color(
			0.4,
			0.4,
			0.4,
			0.6
		)

	draw_texture_rect(
		texture,
		Rect2(icon_position, draw_size),
		false,
		icon_color
	)


# Backup icon if a texture is missing or invalid.
func draw_fallback_icon() -> void:

	var icon_color: Color = get_reward_color()

	if unavailable:
		icon_color = Color("#555555")

	var center: Vector2 = Vector2(
		0,
		-10.0 + float_offset
	)

	draw_circle(
		center,
		10.0,
		icon_color
	)

	draw_circle(
		center,
		10.0,
		Color("#30251E"),
		false,
		2.0
	)


# --------------------------------------------------
# LABELS
# --------------------------------------------------


func draw_reward_label() -> void:

	var font: Font = ThemeDB.fallback_font

	var label_text: String = get_reward_name()

	var label_color: Color = Color("#E8DFD1")

	if highlighted:
		label_color = Color("#F2D15B")

	if unavailable:
		label_color = Color("#777777")

	if claimed:
		label_color = Color("#54CF75")

	var label_y: float = (
		pedestal_size / 2.0 + 14.0
	)

	draw_centered_text(
		font,
		label_text,
		label_y,
		12,
		label_color
	)

	if claimed:

		draw_centered_text(
			font,
			"Selected",
			label_y + 12.0,
			10,
			Color("#54CF75")
		)

	elif unavailable:

		draw_centered_text(
			font,
			"Unavailable",
			label_y + 12.0,
			10,
			Color("#777777")
		)


func draw_centered_text(
	font: Font,
	label_text: String,
	y: float,
	font_size: int,
	color: Color
) -> void:

	var text_width: float = font.get_string_size(
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x

	var text_position: Vector2 = Vector2(
		-text_width / 2.0,
		y
	)

	draw_string_outline(
		font,
		text_position,
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		3,
		Color("#211B17")
	)

	draw_string(
		font,
		text_position,
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		color
	)
