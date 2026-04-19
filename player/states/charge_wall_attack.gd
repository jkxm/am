extends PlayerState

var _data: AttackData = null
var _elapsed: float = 0.0
var _launch_direction: Vector3 = Vector3.ZERO
var _hit_connected: bool = false
var _hitbox_active: bool = false
var _gravity_delay: float = 0.15
var _gravity_active: bool = false
var _active_end: float = 0.0

func enter(_prev_state: String) -> void:
	_data = player.pending_attack
	player.pending_attack = null
	_elapsed = 0.0
	_hit_connected = false
	_hitbox_active = false
	_gravity_active = false

	if _data == null:
		machine.change_to("JumpFall")
		return

	player.stamina.drain_amount(_data.stamina_cost)
	_gravity_delay = player.heavy_weapon.wall_launch_gravity_delay
	_active_end = _data.windup_time + _data.active_time

	var wall_normal: Vector3 = Vector3.ZERO
	if player.wall_detector.has_wall():
		wall_normal = player.wall_detector.wall_normal()
	_launch_direction = _compute_launch_direction(wall_normal)

	player.velocity = _launch_direction * _data.launch_speed
	player.face_direction(_launch_direction, 1.0)
	if player.camera_rig != null:
		var travel_time: float = _data.launch_distance / maxf(_data.launch_speed, 0.1)
		player.camera_rig.boost_follow(travel_time + 0.4)

	print("[ChargeWallAttack] enter %s  dist=%.1f  speed=%.1f  dir=(%.2f, %.2f, %.2f)" % [
		_data.label, _data.launch_distance, _data.launch_speed,
		_launch_direction.x, _launch_direction.y, _launch_direction.z
	])

	if player.heavy_weapon.hitbox.hit_landed.is_connected(_on_hit_landed):
		player.heavy_weapon.hitbox.hit_landed.disconnect(_on_hit_landed)
	player.heavy_weapon.hitbox.hit_landed.connect(_on_hit_landed)

func exit(_next_state: String) -> void:
	if _hitbox_active:
		player.heavy_weapon.deactivate_hitbox()
		_hitbox_active = false
	if player.heavy_weapon.hitbox.hit_landed.is_connected(_on_hit_landed):
		player.heavy_weapon.hitbox.hit_landed.disconnect(_on_hit_landed)

func physics_step(delta: float) -> void:
	if _data == null:
		machine.change_to("JumpFall")
		return

	_elapsed += delta
	_update_hitbox()

	var travel_time: float = _data.launch_distance / maxf(_data.launch_speed, 0.1)
	var gravity_start: float = _active_end + _gravity_delay

	if _elapsed < travel_time:
		player.velocity = _launch_direction * _data.launch_speed
	elif _elapsed < gravity_start:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.air_accel * delta)
		player.velocity.z = move_toward(player.velocity.z, 0.0, player.air_accel * delta)
	else:
		_gravity_active = true
		player.apply_gravity(delta)
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.air_accel * 0.5 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0.0, player.air_accel * 0.5 * delta)

	player.move_and_slide()

	if player.is_on_floor():
		print("[ChargeWallAttack] finish(landed) elapsed=%.2f" % _elapsed)
		_finish_grounded()
		return

	if _elapsed >= _data.total_duration():
		print("[ChargeWallAttack] finish(duration) elapsed=%.2f" % _elapsed)
		machine.change_to("JumpFall")
		return

	if _elapsed > _data.total_duration() * 2.0:
		push_warning("ChargeWallAttack timeout (%s)" % _data.label)
		machine.change_to("JumpFall")
		return

func _compute_launch_direction(wall_normal: Vector3) -> Vector3:
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

func _update_hitbox() -> void:
	var active: bool = _elapsed >= _data.active_start() and _elapsed < _active_end
	if active and not _hitbox_active:
		player.heavy_weapon.activate_hitbox(_data)
		_hitbox_active = true
	elif not active and _hitbox_active:
		player.heavy_weapon.deactivate_hitbox()
		_hitbox_active = false

func _finish_grounded() -> void:
	var move_input: Vector2 = player.read_move_input()
	machine.change_to("WalkRun" if move_input.length() > 0.01 else "Idle")

func _on_hit_landed(hurtbox: Hurtbox, event: DamageEvent) -> void:
	if _hit_connected:
		return
	_hit_connected = true
	print("[ChargeWallAttack] hit t=%.2fs  target=%s  damage=%.1f" % [_elapsed, hurtbox.name if hurtbox != null else "?", event.amount])
	Hitstop.pulse(event.hitstop_ms)
	if player.camera_rig != null:
		player.camera_rig.shake(event.screen_shake_amplitude)
	var point: Vector3 = hurtbox.global_position if hurtbox != null else player.global_position
	var level: int = _data.charge_level if _data != null else 0
	player.on_landed_hit(point, -event.direction, level)
	var target: Node = hurtbox.owner_ref if hurtbox != null else null
	player.deliver_knockback(target, &"wall", point, level, _launch_direction)
