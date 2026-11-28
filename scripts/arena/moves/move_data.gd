@tool
class_name MoveData
extends Resource

@export var name: String = ""
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

@export_group("Cancel Info")
@export var strength: int = 1
@export var cancel_start: int = 0
@export var cancel_end: int = 0
@export var jump_cancel: bool = false
