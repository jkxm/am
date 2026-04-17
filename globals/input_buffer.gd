extends Node

@export var buffer_window_sec: float = 0.15

var _last_action: String = ""
var _last_time: float = -1000.0

func _unhandled_input(event: InputEvent) -> void:
	for action: StringName in InputMap.get_actions():
		var action_str: String = String(action)
		if action_str.begins_with("ui_"):
			continue
		if event.is_action_pressed(action):
			_last_action = action_str
			_last_time = _now()
			return

func consume(action: String) -> bool:
	if _last_action != action:
		return false
	if _now() - _last_time > buffer_window_sec:
		return false
	_last_action = ""
	return true

func peek(action: String) -> bool:
	if _last_action != action:
		return false
	return _now() - _last_time <= buffer_window_sec

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
