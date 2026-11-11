@tool
class_name HitboxData
extends Resource

@export_group("Timing (ticks from start of move)")

# all the set values are for real time hit box previews when editting
# they dont actually change anything else

@export var start_tick: int = 4:
	set(value):
		start_tick = value
		emit_changed()

@export var end_tick: int = 7:
	set(value):
		end_tick = value
		emit_changed()
		

@export_group("Shape")

@export var size: Vector2 = Vector2(24, 16):
	set(value):
		size = value
		emit_changed()

@export var offset: Vector2 = Vector2(20, 0):
	set(value):
		offset = value
		emit_changed()

@export_group("Hit effect")

@export_enum("Low", "Medium", "High") var hit_attribute: String = "Medium"

@export var damage: int = 5:
	set(value):
		damage = value
		emit_changed()

@export var knockback: Vector2 = Vector2(150, -100):
	set(value):
		knockback = value
		emit_changed()

@export var hitstun_frames: int = 12:
	set(value):
		hitstun_frames = value
		emit_changed()

@export var hitfreeze_frames: int = 6:
	set(value):
		hitfreeze_frames = value
		emit_changed()
