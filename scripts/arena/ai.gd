extends Node

# Ranges are in world pixels. Keep the numbers from your old ai.gd if you already tuned them.
@export var stop_range: float = 160.0       # stop walking in once this close
@export var far_range: float = 700.0        # beyond this the boss may dash in
@export var threat_range: float = 400.0     # opponent attacks inside this can trigger a block
@export var hurtbox_margin: float = 40.0    # added to a move's reach to account for the target's body

@export_group("Personality")
@export var aggression: float = 0.6         # 0 to 1, chance to attack when it gets close
@export var block_chance: float = 0.35      # chance to react to an incoming attack
@export var punish_chance: float = 0.7      # chance to punish a whiffed move
@export var reaction_ticks: int = 12        # delay before reacting to an attack

@onready var me: Player = get_parent() as Player
var target: Player

var mode: String = "approach"
var mode_ticks: int = 0
var cooldown: int = 0
var last_target_state: State
var reaction_timer: int = 0
var will_punish: bool = false

# every key the AI can hold; cleared each tick, then the current mode sets what it needs
const HELD_KEYS := ["Left", "Right", "Down", "Block", "Dash"]


func _physics_process(_delta: float) -> void:
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

	var dx: float = target.global_position.x - me.global_position.x
	var dist: float = absf(dx)
	var dir: float = signf(dx)

	cooldown = maxi(cooldown - 1, 0)
	mode_ticks -= 1
	#_watch_target(dist)

	# punish a whiffed move
	#if will_punish and _target_in_recovery() and _can_act():
		#if _try_attack(dist, dir):
			#will_punish = false
			#_set_mode("wait", 20)
#
	#if mode_ticks <= 0:
		#_pick_mode(dist)
	#_run_mode(dist, dir)


# ---------------------------------------------------------------------------
# Choosing what to do
# ---------------------------------------------------------------------------

func _set_mode(new_mode: String, ticks: int) -> void:
	mode = new_mode
	mode_ticks = ticks
	# idle and walk read these from the buffer, so press once when the mode starts
	if new_mode == "dash_in":
		me.buffer.press("Dash")
	elif new_mode == "block":
		me.buffer.press("Block")


func _pick_mode(dist: float) -> void:
	var r: float = randf()
	if dist > far_range:
		if r < 0.3:
			_set_mode("dash_in", 15)
		else:
			_set_mode("approach", randi_range(30, 60))
	elif dist > stop_range:
		if r < 0.6:
			_set_mode("approach", randi_range(20, 45))
		elif r < 0.75:
			_set_mode("wait", randi_range(10, 30))
		elif r < 0.9:
			_set_mode("retreat", randi_range(15, 30))
		else:
			_set_mode("dash_in", 15)
	else:
		if r < aggression:
			_set_mode("attack", 45)
		elif r < aggression + (1.0 - aggression) * 0.5:
			_set_mode("retreat", randi_range(15, 30))
		else:
			_set_mode("wait", randi_range(15, 30))


# turns the current mode into held keys and button presses
func _run_mode(dist: float, dir: float) -> void:
	_release()
	match mode:
		"approach":
			if dist > stop_range:
				_hold_dir(dir)
		"retreat":
			_hold_dir(-dir)
		"block":
			me.ai_held["Block"] = true
		"dash_in":
			_hold_dir(dir)
			me.ai_held["Dash"] = true
		"attack":
			if cooldown == 0 and _can_act():
				if _try_attack(dist, dir):
					cooldown = randi_range(30, 70)
					_set_mode("wait", randi_range(20, 40))
					return
			# nothing in reach yet, so keep closing in
			if dist > stop_range:
				_hold_dir(dir)
		# "wait" holds nothing


# Attacks: chosen from the boss's own moveset, so it works with any weapon
func _try_attack(dist: float, dir: float) -> bool:
	var ms = me.current_moveset
	if ms == null:
		return false

	var options: Array = []
	var total: float = 0.0
	for entry in [["Light", ms.standing_light], ["Medium", ms.standing_medium], ["Heavy", ms.standing_heavy]]:
		var move: MoveData = entry[1]
		if move == null or move.hitboxes.is_empty():
			continue
		if dist > _reach(move) + hurtbox_margin:
			continue
		# slower moves get picked less often
		var weight: float = 1.0 / (1.0 + _startup(move) / 8.0)
		options.append([entry[0], weight])
		total += weight

	if options.is_empty():
		return false

	var roll: float = randf() * total
	var pick: String = options[0][0]
	for o in options:
		roll -= o[1]
		if roll <= 0.0:
			pick = o[0]
			break

	me.face(dir)
	me.buffer.press(pick)
	return true


# how far in front of the character the move's hitboxes reach
func _reach(move: MoveData) -> float:
	var r: float = 0.0
	for box in move.hitboxes:
		if box:
			r = maxf(r, absf(box.offset.x) + box.size.x / 2.0)
	return r


# tick of the first active hitbox
func _startup(move: MoveData) -> int:
	var first: int = 9999
	for box in move.hitboxes:
		if box:
			first = mini(first, box.start_tick)
	return first



func _watch_target(dist: float) -> void:
	var s: State = target.state_machine.current_state
	if s != last_target_state:
		last_target_state = s
		will_punish = randf() < punish_chance
		if s is PlayerAttackState and dist <= threat_range and randf() < block_chance:
			reaction_timer = reaction_ticks

	if reaction_timer > 0:
		reaction_timer -= 1
		if reaction_timer == 0:
			_set_mode("block", 30)


func _target_in_recovery() -> bool:
	var s := target.state_machine.current_state as PlayerAttackState
	if s == null or s.move_data == null:
		return false
	var last_active: int = 0
	for box in s.move_data.hitboxes:
		if box:
			last_active = maxi(last_active, box.end_tick)
	# get() returns null if the cancel feature isn't in attack.gd, which counts as a whiff
	return s.tick >= last_active and s.get("hit_connected") != true


func _can_act() -> bool:
	var s: State = me.state_machine.current_state
	return s is PlayerIdleState or s is PlayerWalkState



# Helpers
func _hold_dir(dir: float) -> void:
	me.ai_held["Left"] = dir < 0.0
	me.ai_held["Right"] = dir > 0.0


func _release() -> void:
	for key in HELD_KEYS:
		me.ai_held[key] = false


func _find_target() -> Player:
	for node in get_tree().get_nodes_in_group("Player"):
		var p: Player = node as Player
		if p and p != me and not p.is_ai:
			return p
	return null
