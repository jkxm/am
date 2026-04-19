extends Node

var _active_until_real: float = -1.0

func pulse(duration_ms: float, scale: float = 0.05) -> void:
	if duration_ms <= 0.0:
		return
	var duration_s: float = duration_ms / 1000.0
	var end_time: float = _now() + duration_s
	if end_time <= _active_until_real:
		return
	_active_until_real = end_time
	Engine.time_scale = scale
	print("[Hitstop] pulse %.0fms scale=%.2f end_in=%.3f" % [duration_ms, scale, duration_s])
	var timer: SceneTreeTimer = get_tree().create_timer(duration_s, true, false, true)
	timer.timeout.connect(func() -> void:
		if _now() >= _active_until_real - 0.001:
			Engine.time_scale = 1.0
			print("[Hitstop] restored time_scale=1.0 at %.3fs" % _now())
	)

func _process(_delta: float) -> void:
	if abs(Engine.time_scale - 1.0) > 0.001 and _now() > _active_until_real + 0.5:
		var slowmo_active: bool = false
		if Engine.has_singleton("Slowmo"):
			slowmo_active = true
		var slowmo_node: Node = get_node_or_null("/root/Slowmo")
		if slowmo_node != null and slowmo_node.has_method("is_active") and slowmo_node.call("is_active"):
			slowmo_active = true
		if slowmo_active:
			return
		push_warning("[Hitstop] time_scale stuck at %.2f (expected 1.0) beyond active_until=%.2f, now=%.2f — forcing restore" % [Engine.time_scale, _active_until_real, _now()])
		Engine.time_scale = 1.0

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
