extends PlayerState

var _data: AttackData = null
var _elapsed: float = 0.0
var _hit_connected: bool = false
var _hitbox_active: bool = false
var _direction: Vector3 = Vector3.ZERO
var _was_on_floor: bool = false
var _was_on_wall: bool = false

func enter(_prev_state: String) -> void:
	_data = player.pending_attack
	_elapsed = 0.0
	_hit_connected = false
	_hitbox_active = false
	player.pending_attack = null

	if _data == null:
		machine.change_to("Idle")
		return

	_direction = _preferred_facing()
	player.face_direction(_direction, 1.0)
	player.stamina.drain_amount(_data.stamina_cost)
	_was_on_floor = player.is_on_floor()
	_was_on_wall = player.is_on_wall()

	print("[Attack] enter %s  duration=%.2fs  cancel=%s@%.0f%%" % [
		_data.label, _data.total_duration(),
		str(_data.has_cancel_window), _data.cancel_window_start_frac * 100.0
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
		machine.change_to("Idle")
		return

	_elapsed += delta

	_update_hitbox()
	_apply_motion(delta)
	player.move_and_slide()

	var now_floor: bool = player.is_on_floor()
	var now_wall: bool = player.is_on_wall()
	if now_floor != _was_on_floor or now_wall != _was_on_wall:
		_was_on_floor = now_floor
		_was_on_wall = now_wall

	if _elapsed >= _data.total_duration():
		print("[Attack] finish %s  elapsed=%.2f" % [_data.label, _elapsed])
		_finish()
		return

	if _data.has_cancel_window and _is_in_cancel_window():
		if InputBuffer.consume("dodge"):
			if player.stamina.try_spend(player.dodge_stamina_cost):
				print("[Attack] dodge-cancel %s at %.2f" % [_data.label, _elapsed])
				machine.change_to("DodgeRoll")
				return

	if _elapsed > _data.total_duration() * 1.5:
		push_warning("Attack timeout (%s): forcing finish at %.2f" % [_data.label, _elapsed])
		_finish()
		return

func _update_hitbox() -> void:
	var in_active: bool = _elapsed >= _data.active_start() and _elapsed < _data.active_end()
	if in_active and not _hitbox_active:
		player.heavy_weapon.activate_hitbox(_data)
		_hitbox_active = true
	elif not in_active and _hitbox_active:
		player.heavy_weapon.deactivate_hitbox()
		_hitbox_active = false

func _apply_motion(delta: float) -> void:
	player.apply_gravity(delta)
	var duration: float = maxf(_data.total_duration(), 0.01)
	var t: float = clampf(_elapsed / duration, 0.0, 1.0)
	var eased: float = ease(t, 2.0)
	var peak_speed: float = 1.5 * _data.forward_motion / duration
	var speed: float = lerpf(peak_speed, 0.0, eased)
	player.velocity.x = _direction.x * speed
	player.velocity.z = _direction.z * speed

func _is_in_cancel_window() -> bool:
	return _elapsed >= _data.cancel_start() and _elapsed < _data.cancel_end()

func _preferred_facing() -> Vector3:
	var move_input: Vector2 = player.read_move_input()
	if move_input.length() > 0.01:
		var d: Vector3 = player.camera_relative_direction(move_input)
		if d.length() > 0.01:
			return d.normalized()
	var mesh_fwd: Vector3 = -player.mesh_root.global_transform.basis.z
	if mesh_fwd.length() > 0.01:
		return mesh_fwd.normalized()
	var basis: Basis = player.camera_rig.get_yaw_basis()
	var forward: Vector3 = -basis.z
	forward.y = 0.0
	return forward.normalized()

func _finish() -> void:
	if player.is_on_floor():
		var move_input: Vector2 = player.read_move_input()
		machine.change_to("WalkRun" if move_input.length() > 0.01 else "Idle")
	else:
		machine.change_to("JumpFall")

func _on_hit_landed(hurtbox: Hurtbox, event: DamageEvent) -> void:
	if _hit_connected:
		return
	_hit_connected = true
	print("[Attack] hit t=%.2fs  target=%s  damage=%.1f" % [_elapsed, hurtbox.name if hurtbox != null else "?", event.amount])
	Hitstop.pulse(event.hitstop_ms)
	if player.camera_rig != null:
		player.camera_rig.shake(event.screen_shake_amplitude)
	player.on_landed_hit()
