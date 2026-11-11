extends Node2D

var rects: Array[Rect2] = []

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 100

func show_rects(new_rects: Array[Rect2]) -> void:
	rects = new_rects
	queue_redraw()

func _draw() -> void:
	if not get_tree().debug_collisions_hint:
		return
	for r in rects:
		draw_rect(r, Color(1.0, 0.2, 0.2, 0.35))
		draw_rect(r, Color(1.0, 0.2, 0.2, 1.0), false, 1.0)
