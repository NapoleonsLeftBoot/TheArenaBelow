class_name InputBuffer
extends RefCounted

const BUFFER_FRAMES: int = 3
const BIG_BUFFER_FRAMES: int = 12

var _press_frames: Dictionary[StringName, int] = {}

func record(event: InputEvent) -> void:
	if event.is_echo() or not event.is_pressed():
		return
	for action in InputMap.get_actions():
		if action.begins_with("ui_"):
			continue
		if event.is_action_pressed(action):
			_press_frames[action] = Engine.get_physics_frames()

func is_buffered_big(action: StringName) -> bool:
	if not _press_frames.has(action):
		return false
	return Engine.get_physics_frames() - _press_frames[action] < BIG_BUFFER_FRAMES

func is_buffered(action: StringName) -> bool:
	if not _press_frames.has(action):
		return false
	return Engine.get_physics_frames() - _press_frames[action] < BUFFER_FRAMES

func consume(action: StringName) -> bool:
	if is_buffered(action):
		_press_frames.erase(action)
		return true
	return false
	
func consume_big(action: StringName) -> bool:
	if is_buffered_big(action):
		_press_frames.erase(action)
		return true
	return false

func clear() -> void:
	_press_frames.clear()
