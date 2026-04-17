extends PlayerState

@export var wall_run_speed: float = 7.5
@export var mount_upward_kick: float = 3.5
@export var stamina_drain_per_sec: float = 30.0
@export var stick_force: float = 12.0
@export var dead_zone: float = 0.1
@export var axis_deadband_deg: float = 22.0
@export var axis_lerp_speed: float = 6.0

var _wall_forward: Vector3 = Vector3.ZERO
var _wall_right: Vector3 = Vector3.ZERO

func enter(_prev_state: String) -> void:
	player.velocity.y = maxf(player.velocity.y, mount_upward_kick)
	_wall_forward = Vector3.ZERO
	_wall_right = Vector3.ZERO
	if player.wall_detector.has_wall():
		_initialize_axes(player.wall_detector.wall_normal())

func physics_step(delta: float) -> void:
	if not player.wall_detector.has_wall():
		machine.change_to("JumpFall")
		return

	if player.is_on_floor():
		machine.change_to("WalkRun" if player.read_move_input().length() > 0.01 else "Idle")
		return

	if not player.stamina.drain_amount(stamina_drain_per_sec * delta):
		machine.change_to("WallCling")
		return

	var move_input := player.read_move_input()
	if move_input.length() < 0.01:
		machine.change_to("WallCling")
		return

	if InputBuffer.consume("jump"):
		machine.change_to("WallJump")
		return

	if InputBuffer.consume("dodge"):
		if player.stamina.try_spend(player.dodge_stamina_cost):
			machine.change_to("WallDash")
			return

	if InputBuffer.consume("attack"):
		machine.change_to("ChargeAttack")
		return

	var wall_normal: Vector3 = player.wall_detector.wall_normal()
	_update_axes(wall_normal, delta)

	var move_dir: Vector3 = _wall_right * move_input.x + _wall_forward * move_input.y
	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()

	var desired: Vector3 = move_dir * wall_run_speed
	desired -= wall_normal * stick_force * delta
	player.velocity = desired

	if move_dir.length() > 0.01:
		var facing: Vector3 = Vector3(move_dir.x, 0.0, move_dir.z)
		if facing.length() > 0.01:
			player.face_direction(facing, delta)
	else:
		player.face_direction(-wall_normal, delta)
	player.move_and_slide()

func _initialize_axes(wall_normal: Vector3) -> void:
	var target: Vector3 = _compute_target_forward(wall_normal)
	if target.length() > 0.01:
		_wall_forward = target
	else:
		_wall_forward = _fallback_forward(wall_normal)
	_wall_right = _wall_forward.cross(wall_normal).normalized()

func _update_axes(wall_normal: Vector3, delta: float) -> void:
	var target: Vector3 = _compute_target_forward(wall_normal)
	if target.length() < 0.01:
		target = _wall_forward if _wall_forward.length() > 0.01 else _fallback_forward(wall_normal)

	if _wall_forward.length() < 0.01:
		_wall_forward = target
	else:
		var angle_deg: float = rad_to_deg(_wall_forward.angle_to(target))
		if angle_deg > axis_deadband_deg:
			var t: float = clampf(axis_lerp_speed * delta, 0.0, 1.0)
			_wall_forward = _wall_forward.slerp(target, t).normalized()

	var projected: Vector3 = _wall_forward - wall_normal * _wall_forward.dot(wall_normal)
	if projected.length() > 0.01:
		_wall_forward = projected.normalized()
	_wall_right = _wall_forward.cross(wall_normal).normalized()

func _compute_target_forward(wall_normal: Vector3) -> Vector3:
	var cam_forward: Vector3 = player.camera_rig.get_camera_forward()
	var forward_on_wall: Vector3 = cam_forward - wall_normal * cam_forward.dot(wall_normal)
	if forward_on_wall.length() >= dead_zone:
		return forward_on_wall.normalized()

	var cam_right: Vector3 = player.camera_rig.get_camera_right()
	var right_on_wall: Vector3 = cam_right - wall_normal * cam_right.dot(wall_normal)
	if right_on_wall.length() >= dead_zone:
		return wall_normal.cross(right_on_wall.normalized()).normalized()

	return Vector3.ZERO

func _fallback_forward(wall_normal: Vector3) -> Vector3:
	var up_on_wall: Vector3 = Vector3.UP - wall_normal * Vector3.UP.dot(wall_normal)
	if up_on_wall.length() > 0.01:
		return up_on_wall.normalized()
	var forward_on_wall: Vector3 = Vector3.FORWARD - wall_normal * Vector3.FORWARD.dot(wall_normal)
	if forward_on_wall.length() > 0.01:
		return forward_on_wall.normalized()
	return Vector3.UP
