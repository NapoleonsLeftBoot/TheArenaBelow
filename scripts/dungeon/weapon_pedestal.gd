extends Node2D

# The Arena Below - Weapon Pedestal
# Displays weapons and allows the player to equip them.


# --------------------------------------------------
# TEXTURES
# --------------------------------------------------


const SWORD_TEXTURE = preload(
    "res://art/dungeon/weapons/sword.tres"
)

const AXE_TEXTURE = preload(
    "res://art/dungeon/weapons/battle_axe.tres"
)

const SPEAR_TEXTURE = preload(
    "res://art/dungeon/weapons/spear.tres"
)


# --------------------------------------------------
# SETTINGS
# --------------------------------------------------


@export var weapon: WeaponData

@export var pedestal_size: float = 44.0
@export var interaction_range: float = 50.0

@export var pedestal_collision_size: Vector2 = (
	Vector2(34, 24)
)

@export var pedestal_collision_offset: Vector2 = (
	Vector2.ZERO
)

@export var float_speed: float = 2.5
@export var float_amount: float = 3.0


# --------------------------------------------------
# STATE
# --------------------------------------------------


var highlighted: bool = false
var selected: bool = false

var animation_time: float = 0.0
var float_offset: float = 0.0


# --------------------------------------------------
# INITIALIZATION
# --------------------------------------------------


func _ready() -> void:

	z_index = 0

	texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	create_pedestal_collision()

	queue_redraw()
	print("NEW PEDESTAL LOADED")


func setup(new_weapon: WeaponData) -> void:

	weapon = new_weapon

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
	body.collision_layer = 1
	body.collision_mask = 0

	var collision: CollisionShape2D = (
		CollisionShape2D.new()
	)

	var rectangle: RectangleShape2D = (
		RectangleShape2D.new()
	)

	rectangle.size = pedestal_collision_size

	collision.shape = rectangle
	collision.position = pedestal_collision_offset

	body.add_child(collision)
	add_child(body)


# --------------------------------------------------
# INTERACTION
# --------------------------------------------------


func is_player_near(
	player_position: Vector2
) -> bool:

	return global_position.distance_to(
		player_position
	) <= interaction_range


func set_highlighted(value: bool) -> void:

	if highlighted == value:
		return

	highlighted = value

	queue_redraw()


func set_selected(value: bool) -> void:

	if selected == value:
		return

	selected = value

	queue_redraw()


func get_weapon() -> WeaponData:

	return weapon


# --------------------------------------------------
# WEAPON TEXTURES
# --------------------------------------------------


func get_weapon_texture() -> Texture2D:

	if weapon == null:
		return null

	match weapon.weapon_type:

		WeaponData.WeaponType.SWORD:
			return SWORD_TEXTURE

		WeaponData.WeaponType.BATTLE_AXE:
			return AXE_TEXTURE

		WeaponData.WeaponType.SPEAR:
			return SPEAR_TEXTURE

		WeaponData.WeaponType.FISTS:
			return null

	return null


# --------------------------------------------------
# DRAWING
# --------------------------------------------------


func _draw() -> void:

	if weapon == null:
		return

	draw_pedestal()
	draw_weapon()
	draw_weapon_name()


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

	# Green border for the equipped weapon.
	if selected:

		draw_rect(
			pedestal_rect.grow(2.0),
			Color("#54CF75"),
			false,
			2.0
		)

	# Gold border when the player is nearby.
	elif highlighted:

		draw_rect(
			pedestal_rect.grow(2.0),
			Color("#F2D15B"),
			false,
			2.0
		)


# Draw the floating weapon.
func draw_weapon() -> void:

	if weapon.weapon_type == WeaponData.WeaponType.FISTS:

		draw_fists()

		return

	var texture: Texture2D = get_weapon_texture()

	if texture == null:
		return

	var texture_size: Vector2 = texture.get_size()

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

	draw_texture_rect(
		texture,
		Rect2(icon_position, draw_size),
		false,
		Color.WHITE
	)


# Draw two fists when no physical weapon is used.
func draw_fists() -> void:

	var fist_y: float = -10.0 + float_offset

	var fist_color: Color = weapon.weapon_color

	var left_fist: Rect2 = Rect2(
		-15.0,
		fist_y - 6.0,
		12.0,
		12.0
	)

	var right_fist: Rect2 = Rect2(
		3.0,
		fist_y - 6.0,
		12.0,
		12.0
	)

	# Dark outlines.
	draw_rect(
		left_fist.grow(1.0),
		Color("#30251E")
	)

	draw_rect(
		right_fist.grow(1.0),
		Color("#30251E")
	)

	# Main fist graphics.
	draw_rect(
		left_fist,
		fist_color
	)

	draw_rect(
		right_fist,
		fist_color
	)

	# Highlights.
	draw_rect(
		Rect2(
			left_fist.position,
			Vector2(12.0, 3.0)
		),
		fist_color.lightened(0.25)
	)

	draw_rect(
		Rect2(
			right_fist.position,
			Vector2(12.0, 3.0)
		),
		fist_color.lightened(0.25)
	)


# Draw the weapon name and selection status.
func draw_weapon_name() -> void:

	var font: Font = ThemeDB.fallback_font

	var label_text: String = weapon.weapon_name

	var label_color: Color = Color("#E8DFD1")

	if selected:

		label_color = Color("#54CF75")

	elif highlighted:

		label_color = Color("#F2D15B")

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

	if selected:

		draw_centered_text(
			font,
			"Equipped",
			label_y + 12.0,
			10,
			Color("#54CF75")
		)


# Draw centered text with a dark outline.
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
