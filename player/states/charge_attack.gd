extends PlayerState

enum ChargeContext { GROUND, WALL, AIR }

@export var glow_intensity_per_level: float = 2.0
@export var glow_color_l0: Color = Color(1.0, 0.9, 0.5, 1.0)
@export var glow_color_l3: Color = Color(1.0, 0.55, 0.1, 1.0)

var _hold_time: float = 0.0
var _level: int = 0
var _context: int = ChargeContext.GROUND

func enter(_prev_state: String) -> void:
	_hold_time = 0.0
	_level = 0
	_context = _detect_context()
	_push_camera_context()
	_update_glow()
	print("[ChargeAttack] enter context=%s  floor=%s  wall=%s" % [_context_name(), str(player.is_on_floor()), str(player.wall_detector.has_wall())])

func exit(_next_state: String) -> void:
	if player.charge_glow != null:
		player.charge_glow.light_energy = 0.0
	if player.trajectory_preview != null:
		player.trajectory_preview.hide_preview()

func physics_step(delta: float) -> void:
	_hold_time += delta
	var weapon: HeavyWeapon = player.heavy_weapon
	var new_level: int = weapon.charge_level_for(_hold_time)
	if new_level != _level:
		_level = new_level
		_update_glow()
		print("[ChargeAttack] level=%d hold=%.2fs" % [_level, _hold_time])

	match _context:
		ChargeContext.GROUND: _physics_ground(delta)
		ChargeContext.WALL: _physics_wall(delta)
		ChargeContext.AIR: _physics_air(delta)

	_update_trajectory()

	if InputBuffer.consume("dodge"):
		if player.stamina.try_spend(player.dodge_stamina_cost):
			match _context:
				ChargeContext.GROUND: machine.change_to("DodgeRoll")
				ChargeContext.WALL: machine.change_to("WallDash")
				ChargeContext.AIR: machine.change_to("AirDash")
			return

	if _context == ChargeContext.GROUND and InputBuffer.consume("jump"):
		player.do_jump()
		_context = ChargeContext.AIR
		_push_camera_context()
		return

	_update_context_if_changed()

	# Air charge cancels on landing without firing (spec: "no attack occurs — they just land normally")
	if _context == ChargeContext.AIR and player.is_on_floor():
		print("[ChargeAttack] air-charge cancel on landing hold=%.2fs" % _hold_time)
		_cancel_to_ground()
		return

	if not Input.is_action_pressed("attack"):
		_release()
		return

func charge_level() -> int:
	return _level

func hold_time() -> float:
	return _hold_time

func _detect_context() -> int:
	if player.is_on_floor():
		return ChargeContext.GROUND
	if player.wall_detector.has_wall():
		return ChargeContext.WALL
	return ChargeContext.AIR

func _update_context_if_changed() -> void:
	var new_context: int = _detect_context()
	if new_context == _context:
		return
	_context = new_context
	_push_camera_context()
	print("[ChargeAttack] context switch -> %s" % _context_name())

func _push_camera_context() -> void:
	if player.camera_rig == null:
		return
	match _context:
		ChargeContext.GROUND: player.camera_rig.set_context(&"ground")
		ChargeContext.WALL: player.camera_rig.set_context(&"wall_charge")
		ChargeContext.AIR: player.camera_rig.set_context(&"air")

func _physics_ground(delta: float) -> void:
	player.apply_gravity(delta)
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	var move_input: Vector2 = player.read_move_input()
	if move_input.length() > 0.01:
		var dir: Vector3 = player.camera_relative_direction(move_input)
		if dir.length() > 0.01:
			var target_yaw: float = atan2(dir.x, dir.z)
			var max_step: float = deg_to_rad(player.heavy_weapon.charge_aim_rotation_speed_deg) * delta
			var current: float = player.mesh_root.rotation.y
			var diff: float = wrapf(target_yaw - current, -PI, PI)
			var step: float = clampf(diff, -max_step, max_step)
			player.mesh_root.rotation.y = current + step
	player.move_and_slide()

func _physics_wall(delta: float) -> void:
	if not player.wall_detector.has_wall():
		_update_context_if_changed()
		return
	var wall_normal: Vector3 = player.wall_detector.wall_normal()
	player.velocity = -wall_normal * 6.0 * delta
	player.move_and_slide()

func _physics_air(delta: float) -> void:
	var weapon: HeavyWeapon = player.heavy_weapon
	var fall_target: float = -weapon.air_charge_fall_speed
	player.velocity.y = maxf(player.velocity.y - player.gravity * 0.5 * delta, fall_target)
	if player.velocity.y < fall_target:
		player.velocity.y = fall_target
	var move_input: Vector2 = player.read_move_input()
	var drift_target: Vector3 = Vector3.ZERO
	if move_input.length() > 0.01:
		var dir: Vector3 = player.camera_relative_direction(move_input)
		drift_target = dir * weapon.air_charge_horizontal_drift
	player.velocity.x = move_toward(player.velocity.x, drift_target.x, player.air_accel * delta)
	player.velocity.z = move_toward(player.velocity.z, drift_target.z, player.air_accel * delta)
	player.move_and_slide()

func _cancel_to_ground() -> void:
	var move_input: Vector2 = player.read_move_input()
	machine.change_to("WalkRun" if move_input.length() > 0.01 else "Idle")

func _release() -> void:
	var weapon: HeavyWeapon = player.heavy_weapon
	print("[ChargeAttack] release hold=%.2fs level=%d context=%s" % [_hold_time, _level, _context_name()])
	match _context:
		ChargeContext.GROUND:
			player.pending_attack = weapon.get_ground_attack(_level)
			machine.change_to("Attack")
		ChargeContext.WALL:
			player.pending_attack = weapon.get_wall_attack(_level)
			machine.change_to("ChargeWallAttack")
		ChargeContext.AIR:
			player.pending_attack = weapon.get_air_attack(_level)
			machine.change_to("AerialAttack")

func _context_name() -> String:
	match _context:
		ChargeContext.GROUND: return "GROUND"
		ChargeContext.WALL: return "WALL"
		ChargeContext.AIR: return "AIR"
	return "?"

func _update_glow() -> void:
	if player.charge_glow == null:
		return
	var t: float = float(_level) / 3.0
	player.charge_glow.light_energy = glow_intensity_per_level * float(_level)
	player.charge_glow.light_color = glow_color_l0.lerp(glow_color_l3, t)

func _update_trajectory() -> void:
	if player.trajectory_preview == null:
		return
	if _context != ChargeContext.WALL or not player.wall_detector.has_wall():
		player.trajectory_preview.hide_preview()
		return
	var preview_attack: AttackData = player.heavy_weapon.get_wall_attack(_level)
	var wall_normal: Vector3 = player.wall_detector.wall_normal()
	var dir: Vector3 = _compute_wall_aim(wall_normal)
	var origin: Vector3 = player.global_position + Vector3(0, 1.0, 0)
	player.trajectory_preview.update_preview(
		origin, dir,
		preview_attack.launch_distance,
		preview_attack.launch_speed,
		preview_attack.active_time,
		player.heavy_weapon.wall_launch_gravity_delay,
		player.gravity
	)

func _compute_wall_aim(wall_normal: Vector3) -> Vector3:
	var pitch_basis: Basis = player.camera_rig.get_pitch_basis()
	var aim: Vector3 = -pitch_basis.z
	if aim.length() < 0.01:
		aim = Vector3.FORWARD
	aim = aim.normalized()
	if wall_normal.length() < 0.01:
		return aim
	var min_angle: float = deg_to_rad(player.heavy_weapon.wall_launch_min_angle_deg)
	var along_normal: float = aim.dot(wall_normal)
	var min_along: float = sin(min_angle)
	if along_normal < min_along:
		var tangent_part: Vector3 = aim - wall_normal * along_normal
		if tangent_part.length() < 0.001:
			tangent_part = Vector3.UP - wall_normal * Vector3.UP.dot(wall_normal)
			if tangent_part.length() < 0.001:
				return wall_normal
		tangent_part = tangent_part.normalized()
		var cos_val: float = cos(min_angle)
		aim = (tangent_part * cos_val + wall_normal * min_along).normalized()
	return aim
