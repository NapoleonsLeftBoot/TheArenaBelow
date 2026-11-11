@tool
class_name MoveData
extends Resource

@export var animation: String = ""


@export var total_frames: int = 17

@export_group("Hitboxes")

@export var hitboxes: Array[HitboxData] = []:
	set(value):
		hitboxes = value
		emit_changed()

@export_group("Movement")

@export var traction: float = 0.8
@export var aerial: bool = false
@export var crouch: bool = false
