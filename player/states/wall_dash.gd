extends PlayerState

@export var dash_distance: float = 2.2
@export var dash_duration: float = 0.3
@export var iframe_start: float = 0.05
@export var iframe_end: float = 0.2
@export var recovery_lockout: float = 0.1
@export var dead_zone: float = 0.1

var _elapsed: float = 0.0
var _direction: Vector3 = Vector3.ZERO

func enter(_prev_state: String) -> void:
	_elapsed = 0.0
	var move_input := player.read_move_input()

	if player.wall_detector.has_wall():
		var wall_normal: Vector3 = player.wall_detector.wall_normal()
		var axes: Array[Vector3] = _wall_axes(wall_normal)
		var wall_forward: Vector3 = axes[0]
		var wall_right: Vector3 = axes[1]
		if move_input.length() < 0.01:
			_direction = -wall_forward if wall_forward.length() > 0.01 else _facing_fallback_on_wall(wall_normal)
		else:
			var dir: Vector3 = wall_right * move_input.x + wall_forward * move_input.y
			if dir.length() > 0.01:
				_direction = dir.normalized()
			else:
				_direction = _facing_fallback_on_wall(wall_normal)
	elif move_input.length() > 0.01:
		_direction = player.camera_relative_direction(move_input).normalized()
	else:
		_direction = -player.mesh_root.global_transform.basis.z
	player.invulnerable = false

func _wall_axes(wall_normal: Vector3) -> Array[Vector3]:
	var cam_up: Vector3 = player.camera_rig.get_camera_up()
	var cam_right: Vector3 = player.camera_rig.get_camera_right()
	var wall_forward: Vector3 = cam_up - wall_normal * cam_up.dot(wall_normal)
	var wall_right: Vector3 = cam_right - wall_normal * cam_right.dot(wall_normal)

	if wall_forward.length() >= dead_zone:
		wall_forward = wall_forward.normalized()
	else:
		wall_forward = Vector3.ZERO

	if wall_right.length() >= dead_zone:
		wall_right = wall_right.normalized()
	else:
		wall_right = Vector3.ZERO

	return [wall_forward, wall_right]

func _facing_fallback_on_wall(wall_normal: Vector3) -> Vector3:
	var mesh_forward: Vector3 = -player.mesh_root.global_transform.basis.z
	var projected: Vector3 = mesh_forward - wall_normal * mesh_forward.dot(wall_normal)
	if projected.length() > 0.01:
		return projected.normalized()
	return Vector3.UP

func exit(_next_state: String) -> void:
	player.invulnerable = false

func physics_step(delta: float) -> void:
	_elapsed += delta
	player.invulnerable = _elapsed >= iframe_start and _elapsed <= iframe_end

	var t: float = clampf(_elapsed / dash_duration, 0.0, 1.0)
	var eased: float = ease(t, 2.0)
	var peak_speed: float = 1.5 * dash_distance / dash_duration
	var speed_curve: float = lerpf(peak_speed, 0.0, eased)
	var dash_velocity: Vector3 = _direction * speed_curve

	if player.wall_detector.has_wall():
		dash_velocity -= player.wall_detector.wall_normal() * 8.0 * delta

	player.velocity = dash_velocity
	var facing: Vector3 = Vector3(_direction.x, 0.0, _direction.z)
	if facing.length() > 0.01:
		player.face_direction(facing, delta)
	player.move_and_slide()

	if _elapsed >= dash_duration + recovery_lockout:
		if player.is_on_floor():
			machine.change_to("WalkRun" if player.read_move_input().length() > 0.01 else "Idle")
		elif player.wall_detector.has_wall():
			machine.change_to("WallRun" if player.read_move_input().length() > 0.01 else "WallCling")
		else:
			machine.change_to("JumpFall")
