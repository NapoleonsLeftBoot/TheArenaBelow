
@tool
class_name HitboxPreview
extends Node2D

@export var move_data: MoveData:
	set(value):
		if move_data != null:
			if move_data.changed.is_connected(_on_move_changed):
				move_data.changed.disconnect(_on_move_changed)

		move_data = value
		_connect_move()
		queue_redraw()

@export var animation_player: AnimationPlayer
@export var animation_name: StringName
@export var ticks_per_second: float = 60.0

@export_range(0, 100, 1) var preview_tick: int = 0:
	set(value):
		preview_tick = value
		_update_animation()
		queue_redraw()

@export_enum("Right:1", "Left:-1") var preview_facing: int = 1:
	set(value):
		preview_facing = value
		queue_redraw()

@export var show_all_hitboxes: bool = false:
	set(value):
		show_all_hitboxes = value
		queue_redraw()

var _connected_hitboxes: Array[HitboxData] = []

func _update_animation() -> void:
	if not Engine.is_editor_hint():
		return

	if animation_player == null:
		return

	if not animation_player.has_animation(animation_name):
		return

	var animation := animation_player.get_animation(animation_name)

	var time := float(preview_tick) / ticks_per_second
	time = clampf(time, 0.0, animation.length)

	animation_player.play(animation_name)
	animation_player.seek(time, true)
	animation_player.pause()

func _ready() -> void:
	_connect_move()
	queue_redraw()


func _connect_move() -> void:
	if not is_node_ready():
		return

	if move_data == null:
		_refresh_hitbox_connections()
		return

	if not move_data.changed.is_connected(_on_move_changed):
		move_data.changed.connect(_on_move_changed)

	_refresh_hitbox_connections()


func _refresh_hitbox_connections() -> void:
	for box in _connected_hitboxes:
		if is_instance_valid(box):
			if box.changed.is_connected(_on_hitbox_changed):
				box.changed.disconnect(_on_hitbox_changed)

	_connected_hitboxes.clear()

	if move_data == null:
		return

	for box in move_data.hitboxes:
		if box == null:
			continue

		if not box.changed.is_connected(_on_hitbox_changed):
			box.changed.connect(_on_hitbox_changed)

		_connected_hitboxes.append(box)


func _on_move_changed() -> void:
	_refresh_hitbox_connections()
	queue_redraw()


func _on_hitbox_changed() -> void:
	queue_redraw()


func _draw() -> void:
	if move_data == null:
		return
		
	for i in range(move_data.hitboxes.size()):
		var box := move_data.hitboxes[i]

		if box == null:
			continue

		var active: bool = false
		if preview_tick >= box.start_tick and preview_tick < box.end_tick:
			active = true
		else:
			active = false

		if not active and not show_all_hitboxes:
			continue

		var center := Vector2(
			box.offset.x * preview_facing,
			box.offset.y
		)
		
		var rect := Rect2(
			center - box.size / 2.0,
			box.size
		)

		var color := Color.RED if active else Color.ORANGE

		# fill for rectangle
		draw_rect(
			rect,
			Color(color.r, color.g, color.b, 0.3),
			true
		)

		# rectangle border
		draw_rect(
			rect,
			color,
			false,
			.5
		)

		# center of rectange
		draw_circle(center, .5, Color.YELLOW)

		# hitbox #
		draw_string(
			ThemeDB.fallback_font,
			center + Vector2(0, -box.size.y / 2.0 - 2),
			"Hitbox %d" % (i + 1),
			HORIZONTAL_ALIGNMENT_CENTER,
			-1,
			7,
			color
		)
		
		#vector arrow for seeing launch angle
		draw_line(
			center,
			box.knockback,
			Color(0.932, 0.586, 0.812, 1.0),
			0.5
		)
		
		var direction = (center - box.knockback).normalized()
		var left = box.knockback + direction.rotated(deg_to_rad(30)) * 10.0
		var right = box.knockback + direction.rotated(deg_to_rad(-30)) * 10.0
		
		draw_line(
				box.knockback,
				left,
				Color(0.932, 0.586, 0.812, 1.0),
				0.5
			)
			
		draw_line(
				box.knockback,
				right,
				Color(0.932, 0.586, 0.812, 1.0),
				0.5
			)
	
		
