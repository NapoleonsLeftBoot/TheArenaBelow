extends CanvasLayer

# The Arena Below - Dungeon HUD
# Existing HUD nodes are preserved. Magic HUD is built in code.
# Reference: https://docs.godotengine.org/en/stable/classes/class_progressbar.html

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var status_label: Label = $StatusLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var interaction_label: Label = $InteractionLabel
@onready var upgrade_label: Label = $UpgradeLabel

var magic_panel: PanelContainer
var mana_bar: ProgressBar
var mana_label: Label
var firebolt_label: Label
var shield_label: Label
var displayed_mana: float = 100.0
var displayed_max_mana: float = 100.0
var firebolt_remaining: float = 0.0
var shield_remaining: float = 0.0
var shield_is_active: bool = false

const FIREBOLT_COST: float = 25.0
const SHIELD_COST: float = 40.0

func _ready() -> void:
	status_label.text = ""
	health_bar.show_percentage = false
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.3)
	health_bar.add_theme_stylebox_override("fill", fill_style)
	weapon_label.text = "Weapon: None"
	interaction_label.text = ""
	interaction_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_label.offset_left = -300.0
	interaction_label.offset_right = 300.0
	interaction_label.offset_top = -80.0
	interaction_label.offset_bottom = -20.0
	interaction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interaction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_label.add_theme_color_override("font_outline_color", Color.BLACK)
	interaction_label.add_theme_constant_override("outline_size", 6)
	update_upgrades()
	build_magic_hud()
	update_mana(displayed_mana, displayed_max_mana)
	update_magic_cooldowns(0.0, 0.0)

func build_magic_hud() -> void:
	# A CanvasLayer accepts Control children. This keeps the existing scene intact.
	magic_panel = PanelContainer.new()
	magic_panel.name = "MagicPanel"
	magic_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	magic_panel.offset_left = -244.0
	magic_panel.offset_top = 12.0
	magic_panel.offset_right = -12.0
	magic_panel.offset_bottom = 122.0
	magic_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.13, 0.2, 0.88)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(10)
	magic_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(magic_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	magic_panel.add_child(layout)

	mana_label = Label.new()
	mana_label.name = "ManaLabel"
	mana_label.text = "Mana: 100 / 100"
	mana_label.add_theme_color_override("font_color", Color(0.75, 0.86, 1.0))
	layout.add_child(mana_label)

	mana_bar = ProgressBar.new()
	mana_bar.name = "ManaBar"
	mana_bar.custom_minimum_size = Vector2(210, 13)
	mana_bar.show_percentage = false
	mana_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mana_fill := StyleBoxFlat.new()
	mana_fill.bg_color = Color(0.26, 0.53, 0.95)
	mana_fill.set_corner_radius_all(3)
	mana_bar.add_theme_stylebox_override("fill", mana_fill)
	layout.add_child(mana_bar)

	firebolt_label = Label.new()
	firebolt_label.name = "FireboltLabel"
	layout.add_child(firebolt_label)

	shield_label = Label.new()
	shield_label.name = "ShieldLabel"
	layout.add_child(shield_label)

func update_health(current_health: int, maximum_health: int) -> void:
	health_bar.max_value = maximum_health
	health_bar.value = current_health
	health_label.text = "Health: %d / %d" % [current_health, maximum_health]

func update_weapon(weapon: WeaponData) -> void:
	if weapon == null:
		weapon_label.text = "Weapon: None"
		weapon_label.modulate = Color.WHITE
		return
	weapon_label.text = "Weapon: " + weapon.weapon_name
	weapon_label.modulate = weapon.weapon_color

func update_upgrades() -> void:
	upgrade_label.text = "Damage Bonus: +%d | Max HP Bonus: +%d" % [RunData.bonus_damage, RunData.bonus_max_health]

func update_mana(current_mana: float, maximum_mana: float) -> void:
	displayed_mana = current_mana
	displayed_max_mana = maximum_mana
	if not is_instance_valid(mana_bar):
		return
	mana_bar.max_value = maxf(maximum_mana, 1.0)
	mana_bar.value = current_mana
	mana_label.text = "Mana: %.0f / %.0f" % [current_mana, maximum_mana]
	refresh_spell_labels()

func update_magic_cooldowns(firebolt_time: float, shield_time: float) -> void:
	firebolt_remaining = firebolt_time
	shield_remaining = shield_time
	refresh_spell_labels()

func on_shield_started() -> void:
	shield_is_active = true
	refresh_spell_labels()

func on_shield_ended() -> void:
	shield_is_active = false
	refresh_spell_labels()

func refresh_spell_labels() -> void:
	if not is_instance_valid(firebolt_label) or not is_instance_valid(shield_label):
		return
	if firebolt_remaining > 0.0:
		firebolt_label.text = "Q Firebolt (25 MP): %.1fs" % firebolt_remaining
		firebolt_label.modulate = Color(1.0, 0.77, 0.45)
	elif displayed_mana + 0.0001 < FIREBOLT_COST:
		firebolt_label.text = "Q Firebolt (25 MP): NOT ENOUGH MANA"
		firebolt_label.modulate = Color(1.0, 0.48, 0.48)
	else:
		firebolt_label.text = "Q Firebolt (25 MP): READY"
		firebolt_label.modulate = Color(0.55, 1.0, 0.7)

	if shield_is_active:
		shield_label.text = "R Shield (40 MP): ACTIVE"
		shield_label.modulate = Color(0.55, 0.8, 1.0)
	elif shield_remaining > 0.0:
		shield_label.text = "R Shield (40 MP): %.1fs" % shield_remaining
		shield_label.modulate = Color(1.0, 0.77, 0.45)
	elif displayed_mana + 0.0001 < SHIELD_COST:
		shield_label.text = "R Shield (40 MP): NOT ENOUGH MANA"
		shield_label.modulate = Color(1.0, 0.48, 0.48)
	else:
		shield_label.text = "R Shield (40 MP): READY"
		shield_label.modulate = Color(0.55, 1.0, 0.7)

func show_interaction(message: String) -> void:
	interaction_label.text = message
	interaction_label.show()

func hide_interaction() -> void:
	interaction_label.text = ""
	interaction_label.hide()

func show_defeat() -> void:
	hide_interaction()
	status_label.text = "PLAYER DEFEATED"
	status_label.modulate = Color(1.0, 0.3, 0.3)

func show_completion() -> void:
	status_label.text = "DUNGEON COMPLETED"
	status_label.modulate = Color(0.3, 1.0, 0.3)
