extends Camera2D

@export var player_1: Player
@export var player_2: Player

@export var min_zoom: float = 0.75
@export var max_zoom: float = 1.25
@export var horizontal_padding: float = 250.0
@export var vertical_padding: float = 400.0
@export var zoom_speed: float = 8.0



func _process(delta: float) -> void:
	if not (player_1 or player_2):
		return
	var midpoint := (player_1.global_position + player_2.global_position) * 0.5
	global_position = midpoint
	var distance_x := absf(player_1.global_position.x - player_2.global_position.x) + horizontal_padding
	var distance_y := absf(player_1.global_position.y - player_2.global_position.y) + vertical_padding
	
	var viewport_size := get_viewport_rect().size
	
	var zoom_x := viewport_size.x / maxf(distance_x, 1.0)
	var zoom_y := viewport_size.y / maxf(distance_y, 1.0)
	
	var desired_zoom_val := minf(zoom_x, zoom_y)
	desired_zoom_val = clampf(desired_zoom_val, min_zoom, max_zoom)
	
	var target_zoom := Vector2(desired_zoom_val, desired_zoom_val)
	zoom = zoom.lerp(target_zoom, zoom_speed * delta)
