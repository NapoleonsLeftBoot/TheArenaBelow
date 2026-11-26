class_name WeaponMoveset
extends Resource

@export_group("Standing")
@export var standing_light: MoveData
@export var standing_medium: MoveData
@export var standing_heavy: MoveData

@export_group("Crouching")
@export var crouch_light: MoveData
@export var crouch_medium: MoveData
@export var crouch_heavy: MoveData

@export_group("Aerial")
@export var air_light: MoveData
@export var air_medium: MoveData
@export var air_heavy: MoveData

@export_group("General_Movement")
@export var idle: MoveData
@export var walk: MoveData
@export var jump_squat: MoveData
@export var jump: MoveData
@export var walljump: MoveData
@export var fall: MoveData
@export var block: MoveData
@export var land: MoveData
@export var crouch: MoveData
@export var crouch_block: MoveData
@export var crouch_unblock: MoveData
@export var uncrouch: MoveData
@export var hitstun: MoveData
@export var ko: MoveData
@export var dash: MoveData
@export var back_dash: MoveData
@export var land_to_idle: MoveData
@export var walljump_squat: MoveData
@export var walljump_to_fall: MoveData
@export var land_dash: MoveData
@export var away_walljump_squat: MoveData
@export var away_walljump_to_fall: MoveData
