extends Node

var _timer: float = 0.0
var _active_scale: float = 1.0

func is_active() -> bool:
	return _timer > 0.0

func apply(time_scale: float, duration: float) -> void:
	if duration <= 0.0:
		return
	if Engine.time_scale < 1.0 and time_scale >= _active_scale:
		return
	_active_scale = time_scale
	_timer = duration
	Engine.time_scale = time_scale

func _process(_delta: float) -> void:
	if _timer <= 0.0:
		return
	var real_delta: float = _delta
	if Engine.time_scale > 0.001:
		real_delta = _delta / Engine.time_scale
	_timer -= real_delta
	if _timer <= 0.0:
		_timer = 0.0
		_active_scale = 1.0
		if absf(Engine.time_scale - 1.0) > 0.001:
			Engine.time_scale = 1.0
