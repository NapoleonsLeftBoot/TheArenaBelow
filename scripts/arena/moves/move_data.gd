class_name MoveData
extends Resource

@export var animation: String = ""

@export_group("Frames (physics ticks)")
@export var startup_frames: int = 4
@export var active_frames: int = 3
@export var recovery_frames: int = 10

@export_group("Hitbox")
@export var hitbox_size: Vector2 = Vector2(24, 16)
@export var hitbox_offset: Vector2 = Vector2(20, 0)   # x is opposite when facing left

@export_group("Hit effect")
@export var damage: int = 5
@export var hitfreeze_frames: int = 6 			#freezes both players to add juice
@export var knockback: Vector2 = Vector2(150, -100)   # x is opposite when facing left
@export var hitstun_frames: int = 12   # how long target is stunned

@export_group("Movement")
@export var traction: float = 0.8 
@export var aerial: bool = false 					#for aerial attacks
