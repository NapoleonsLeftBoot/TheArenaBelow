extends Node

@export var attack_range: float = 45.0   # attacks when closer than this numbah
@export var stop_range: float = 35.0     # stop getting closer at this point
@export var cooldown_min: float = 0.6
@export var cooldown_max: float = 1.4


@onready var me: Player = get_parent() as Player
var target: Player
var cooldown: float = 1.0

func _physics_process(delta: float) -> void:
	if me.is_ko:
		_release()
		return
	if me.hitfreeze_ticks > 0:
		return

	if target == null or not is_instance_valid(target):
		target = _find_target()
	if target == null or target.is_ko:
		_release()
		return

	var x: float = target.global_position.x - me.global_position.x
	var dist: float = absf(x)
	var dir: float = signf(x)

	# walk to player until close enough to attack
	me.ai_held["Left"] = dir < 0.0 and dist > stop_range
	me.ai_held["Right"] = dir > 0.0 and dist > stop_range

	# attack and wait a bit
	cooldown -= delta
	if dist <= attack_range and cooldown <= 0.0:
		me.buffer.press("Jab")
		cooldown = randf_range(cooldown_min, cooldown_max)

func _find_target() -> Player:
	for node in get_tree().get_nodes_in_group("Player"):
		var p: Player = node as Player
		if p and p != me and not p.is_ai:
			return p
	return null

func _release() -> void:
	me.ai_held["Left"] = false
	me.ai_held["Right"] = false
