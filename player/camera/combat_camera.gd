class_name CombatCamera
extends Node3D

@export var player_path: NodePath

@export_group("Input")
@export var mouse_sensitivity: float = 0.002
@export var stick_sensitivity: float = 2.0
@export var invert_y: bool = false

@export_group("Orbit")
@export var pitch_min_deg: float = -89.0
@export var pitch_max_deg: float = 89.0
@export var orbit_lerp_speed: float = 8.0

@export_group("Zoom — Distance")
@export var base_distance: float = 4.0
@export var wall_distance: float = 6.0
@export var air_distance: float = 5.0
@export var wall_charge_distance: float = 6.0
@export var zoom_lerp_speed: float = 5.0

@export_group("Zoom — Height Offset")
@export var base_height_offset: float = 1.5
@export var wall_height_offset: float = 2.0
@export var air_height_offset: float = 2.0
@export var wall_charge_height_offset: float = 2.0

@export_group("Pitch Bias")
@export var ground_pitch_bias: float = 15.0
@export var wall_pitch_bias: float = 10.0
@export var air_pitch_bias: float = 20.0
@export var wall_charge_pitch_bias: float = 5.0
@export var pitch_bias_return_speed: float = 1.0
@export var pitch_bias_idle_time: float = 1.5
@export var pitch_bias_input_threshold: float = 0.5
@export var pitch_bias_dead_zone_deg: float = 5.0

@export_group("Horizontal Offset")
@export var ground_offset: float = 0.8
@export var wall_offset: float = 1.0
@export var air_offset: float = 0.5
@export var wall_charge_offset: float = 1.2
@export var horizontal_offset_lerp_speed: float = 3.0
@export var offset_flip_enabled: bool = false
@export var offset_flip_lerp_speed: float = 1.5
@export var offset_flip_hysteresis: float = 0.3

@export_group("Vertical Framing Offset")
@export var ground_vertical_offset: float = 0.5
@export var wall_vertical_offset: float = 0.3
@export var air_vertical_offset: float = 0.8
@export var wall_charge_vertical_offset: float = 0.3

@export_group("FOV")
@export var ground_fov: float = 70.0
@export var wall_fov: float = 75.0
@export var air_fov: float = 75.0
@export var wall_charge_fov: float = 65.0
@export var fov_lerp_speed: float = 4.0

@export_group("Recenter")
@export var recenter_lerp_boost: float = 15.0

@export_group("Shake")
@export var shake_decay: float = 8.0
@export var shake_scale: float = 0.12

@onready var _yaw: Node3D = $Yaw
@onready var _pitch: Node3D = $Yaw/Pitch
@onready var _camera: Camera3D = $Yaw/Pitch/Camera3D

var _player: Node3D = null
var _captured: bool = false

var _current_context: StringName = &"ground"
var _eff_distance: float = 4.0
var _eff_height: float = 1.5
var _eff_pitch_bias: float = 15.0
var _eff_horizontal: float = 0.8
var _eff_vertical: float = 0.5
var _eff_horizontal_sign: float = 1.0
var _recenter_boost_timer: float = 0.0
var _follow_boost_timer: float = 0.0
var _shake_amplitude: float = 0.0
var _shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _time_since_pitch_input: float = 999.0
var _mouse_events_since_log: int = 0
var _last_input_log: float = 0.0

func _ready() -> void:
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as Node3D
	_capture_mouse(true)
	_eff_distance = _target_distance()
	_eff_height = _target_height()
	_eff_pitch_bias = _target_pitch_bias()
	_eff_horizontal = _target_horizontal()
	_eff_vertical = _target_vertical()
	_camera.position = Vector3(0, 0, _eff_distance)
	_camera.fov = _target_fov()
	_pitch.rotation.x = -deg_to_rad(_eff_pitch_bias)
	if _player != null:
		global_position = _player.global_position + Vector3(0, _eff_height, 0)

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("toggle_mouse_capture") and event.is_action_pressed("toggle_mouse_capture"):
		_capture_mouse(not _captured)
		return
	if InputMap.has_action("recenter_camera") and event.is_action_pressed("recenter_camera"):
		_recenter()
		return
	if not _captured:
		if event is InputEventMouseMotion:
			var now: float = Time.get_ticks_msec() / 1000.0
			if now - _last_input_log > 1.0:
				_last_input_log = now
				print("[Camera] mouse motion arrived but NOT captured")
		return
	if event is InputEventMouseMotion:
		_mouse_events_since_log += 1
		var m: InputEventMouseMotion = event
		_yaw.rotate_y(-m.relative.x * mouse_sensitivity)
		var dy: float = m.relative.y * mouse_sensitivity
		if invert_y:
			dy = -dy
		var requested: float = _pitch.rotation.x - dy
		var clamped: float = clampf(requested, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
		if not is_equal_approx(requested, clamped) and absf(m.relative.y) >= pitch_bias_input_threshold:
			var hit: String = "top" if requested > clamped else "bottom"
			print("[Camera] pitch clamp hit: %s  requested=%.1f°  limit=[%.1f°, %.1f°]" % [
				hit, rad_to_deg(requested), pitch_min_deg, pitch_max_deg
			])
		_pitch.rotation.x = clamped
		if absf(m.relative.y) >= pitch_bias_input_threshold:
			_time_since_pitch_input = 0.0

func _process(delta: float) -> void:
	if _player == null:
		return
	_time_since_pitch_input += delta
	_lerp_context_values(delta)
	_apply_pivot(delta)
	_apply_pitch_bias(delta)
	_apply_pitch_clamp()
	_apply_fov(delta)
	_apply_shake(delta)
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_input_log > 1.0:
		_last_input_log = now
		var os_mode: String = "?"
		match Input.mouse_mode:
			Input.MOUSE_MODE_VISIBLE: os_mode = "VISIBLE"
			Input.MOUSE_MODE_HIDDEN: os_mode = "HIDDEN"
			Input.MOUSE_MODE_CAPTURED: os_mode = "CAPTURED"
			Input.MOUSE_MODE_CONFINED: os_mode = "CONFINED"
			Input.MOUSE_MODE_CONFINED_HIDDEN: os_mode = "CONFINED_HIDDEN"
		print("[Camera] mouse events/sec: %d  _captured=%s  os_mode=%s  boost=%.2f  context=%s" % [
			_mouse_events_since_log, str(_captured), os_mode, _follow_boost_timer, String(_current_context)
		])
		_mouse_events_since_log = 0
		if _captured and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			print("[Camera] mode drift detected — forcing recapture")
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_context(context: StringName) -> void:
	if context == _current_context:
		return
	print("[Camera] context %s -> %s" % [String(_current_context), String(context)])
	_current_context = context

func set_camera_context(context: StringName) -> void:
	set_context(context)

func get_camera_forward() -> Vector3:
	return -_camera.global_transform.basis.z

func get_camera_right() -> Vector3:
	return _camera.global_transform.basis.x

func get_yaw_basis() -> Basis:
	return _yaw.global_transform.basis

func get_pitch_basis() -> Basis:
	return _pitch.global_transform.basis

func get_camera_node() -> Camera3D:
	return _camera

func shake(amplitude: float) -> void:
	_shake_amplitude = maxf(_shake_amplitude, amplitude)

func current_context() -> StringName:
	return _current_context

func effective_distance() -> float:
	return _eff_distance

func effective_height() -> float:
	return _eff_height

func effective_pitch_bias() -> float:
	return _eff_pitch_bias

func effective_horizontal_offset() -> float:
	return _eff_horizontal * _eff_horizontal_sign

func effective_vertical_offset() -> float:
	return _eff_vertical

func effective_fov() -> float:
	return _camera.fov

func set_ground_pitch_bias(v: float) -> void: ground_pitch_bias = v
func set_wall_pitch_bias(v: float) -> void: wall_pitch_bias = v
func set_air_pitch_bias(v: float) -> void: air_pitch_bias = v
func set_wall_charge_pitch_bias(v: float) -> void: wall_charge_pitch_bias = v
func set_ground_offset(v: float) -> void: ground_offset = v
func set_wall_offset(v: float) -> void: wall_offset = v
func set_air_offset(v: float) -> void: air_offset = v
func set_wall_charge_offset(v: float) -> void: wall_charge_offset = v
func set_ground_vertical_offset(v: float) -> void: ground_vertical_offset = v
func set_wall_vertical_offset(v: float) -> void: wall_vertical_offset = v
func set_air_vertical_offset(v: float) -> void: air_vertical_offset = v
func set_wall_charge_vertical_offset(v: float) -> void: wall_charge_vertical_offset = v
func set_ground_fov(v: float) -> void: ground_fov = v
func set_wall_fov(v: float) -> void: wall_fov = v
func set_air_fov(v: float) -> void: air_fov = v
func set_wall_charge_fov(v: float) -> void: wall_charge_fov = v

func _target_distance() -> float:
	match _current_context:
		&"ground": return base_distance
		&"wall": return wall_distance
		&"air": return air_distance
		&"wall_charge": return wall_charge_distance
	return base_distance

func _target_height() -> float:
	match _current_context:
		&"ground": return base_height_offset
		&"wall": return wall_height_offset
		&"air": return air_height_offset
		&"wall_charge": return wall_charge_height_offset
	return base_height_offset

func _target_pitch_bias() -> float:
	match _current_context:
		&"ground": return ground_pitch_bias
		&"wall": return wall_pitch_bias
		&"air": return air_pitch_bias
		&"wall_charge": return wall_charge_pitch_bias
	return ground_pitch_bias

func _target_horizontal() -> float:
	match _current_context:
		&"ground": return ground_offset
		&"wall": return wall_offset
		&"air": return air_offset
		&"wall_charge": return wall_charge_offset
	return ground_offset

func _target_vertical() -> float:
	match _current_context:
		&"ground": return ground_vertical_offset
		&"wall": return wall_vertical_offset
		&"air": return air_vertical_offset
		&"wall_charge": return wall_charge_vertical_offset
	return ground_vertical_offset

func _target_fov() -> float:
	match _current_context:
		&"ground": return ground_fov
		&"wall": return wall_fov
		&"air": return air_fov
		&"wall_charge": return wall_charge_fov
	return ground_fov

func _target_horizontal_sign() -> float:
	if not offset_flip_enabled:
		return _eff_horizontal_sign if _eff_horizontal_sign != 0.0 else 1.0
	var dot: float = 0.0
	match _current_context:
		&"wall", &"wall_charge":
			var wall_normal: Vector3 = _query_player_wall_normal()
			if wall_normal.length() > 0.01:
				var yaw_right: Vector3 = _yaw.global_transform.basis.x
				dot = -yaw_right.dot(wall_normal)
		&"ground":
			var monster: Node3D = _find_monster()
			if monster != null and _player != null:
				var to_monster: Vector3 = monster.global_position - _player.global_position
				to_monster.y = 0.0
				if to_monster.length() > 0.01:
					var yaw_right2: Vector3 = _yaw.global_transform.basis.x
					dot = -yaw_right2.dot(to_monster.normalized())
	if dot > offset_flip_hysteresis:
		return 1.0
	if dot < -offset_flip_hysteresis:
		return -1.0
	return _eff_horizontal_sign if _eff_horizontal_sign != 0.0 else 1.0

func _query_player_wall_normal() -> Vector3:
	if _player == null:
		return Vector3.ZERO
	if _player.has_method("wall_detector_has_wall") and _player.has_method("wall_detector_normal"):
		if _player.call("wall_detector_has_wall"):
			return _player.call("wall_detector_normal")
	var wall_detector: Node = _player.get_node_or_null("WallDetector")
	if wall_detector != null and wall_detector.has_method("has_wall") and wall_detector.call("has_wall"):
		return wall_detector.call("wall_normal")
	return Vector3.ZERO

func _find_monster() -> Node3D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var nodes: Array = tree.get_nodes_in_group(&"monsters")
	for n: Node in nodes:
		if n is Node3D:
			return n as Node3D
	return null

func _lerp_context_values(delta: float) -> void:
	var t: float = clampf(zoom_lerp_speed * delta, 0.0, 1.0)
	_eff_distance = lerpf(_eff_distance, _target_distance(), t)
	_eff_height = lerpf(_eff_height, _target_height(), t)
	_eff_pitch_bias = lerpf(_eff_pitch_bias, _target_pitch_bias(), t)
	_camera.position = Vector3(0, 0, _eff_distance)

	var target_horizontal: float = _target_horizontal()
	_eff_horizontal = lerpf(_eff_horizontal, target_horizontal, clampf(horizontal_offset_lerp_speed * delta, 0.0, 1.0))

	var target_sign: float = _target_horizontal_sign()
	_eff_horizontal_sign = lerpf(_eff_horizontal_sign, target_sign, clampf(offset_flip_lerp_speed * delta, 0.0, 1.0))

	_eff_vertical = lerpf(_eff_vertical, _target_vertical(), clampf(horizontal_offset_lerp_speed * delta, 0.0, 1.0))

func _apply_pivot(delta: float) -> void:
	var base: Vector3 = _player.global_position + Vector3(0, _eff_height + _eff_vertical, 0)
	var yaw_right: Vector3 = _yaw.global_transform.basis.x
	base += yaw_right * (_eff_horizontal * _eff_horizontal_sign)
	if _follow_boost_timer > 0.0:
		_follow_boost_timer = maxf(0.0, _follow_boost_timer - delta)
		global_position = base
	else:
		var speed: float = orbit_lerp_speed + _recenter_boost_timer
		global_position = global_position.lerp(base, clampf(speed * delta, 0.0, 1.0))
	if _recenter_boost_timer > 0.0:
		_recenter_boost_timer = maxf(0.0, _recenter_boost_timer - recenter_lerp_boost * delta)

func boost_follow(seconds: float) -> void:
	_follow_boost_timer = maxf(_follow_boost_timer, seconds)

func _apply_pitch_bias(delta: float) -> void:
	if _time_since_pitch_input < pitch_bias_idle_time:
		return
	var target_rotation: float = -deg_to_rad(_eff_pitch_bias)
	target_rotation = clampf(target_rotation, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	var current: float = _pitch.rotation.x
	var diff_rad: float = target_rotation - current
	if absf(diff_rad) < deg_to_rad(pitch_bias_dead_zone_deg):
		return
	var max_step: float = deg_to_rad(pitch_bias_return_speed) * delta
	var step: float = clampf(diff_rad, -max_step, max_step)
	_pitch.rotation.x = current + step

func _apply_pitch_clamp() -> void:
	_pitch.rotation.x = clampf(_pitch.rotation.x, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))

func _apply_fov(delta: float) -> void:
	var target: float = _target_fov()
	_camera.fov = lerpf(_camera.fov, target, clampf(fov_lerp_speed * delta, 0.0, 1.0))

func _apply_shake(delta: float) -> void:
	if _shake_amplitude < 0.001:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0
		return
	_camera.h_offset = _shake_rng.randf_range(-1.0, 1.0) * _shake_amplitude * shake_scale
	_camera.v_offset = _shake_rng.randf_range(-1.0, 1.0) * _shake_amplitude * shake_scale
	_shake_amplitude = maxf(0.0, _shake_amplitude - shake_decay * delta)

func _recenter() -> void:
	_recenter_boost_timer = recenter_lerp_boost

func _capture_mouse(enable: bool) -> void:
	_captured = enable
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enable else Input.MOUSE_MODE_VISIBLE
