extends WCState

var _data: WCAttackData = null
var _elapsed: float = 0.0
var _hitbox_active: bool = false
var _advance_dir: Vector3 = Vector3.ZERO
var _projectile_spawned: int = 0
var _next_barrage_time: float = 0.0
var _dive_target: Vector3 = Vector3.ZERO
var _dive_started: bool = false
var _dive_landed: bool = false

func enter(_prev: String) -> void:
	_data = monster.pending_attack
	monster.pending_attack = null
	_elapsed = 0.0
	_hitbox_active = false
	_projectile_spawned = 0
	_next_barrage_time = 0.0
	_dive_started = false
	_dive_landed = false

	if _data == null:
		machine.change_to(monster.default_combat_state())
		return

	if monster.player != null:
		var to_player: Vector3 = monster.player.global_position - monster.global_position
		if monster.is_on_wall_surface:
			_advance_dir = to_player.normalized()
		else:
			to_player.y = 0.0
			if to_player.length() > 0.01:
				_advance_dir = to_player.normalized()
				monster.face_toward(_advance_dir, 1.0)

	if _data.kind == WCAttackData.Kind.DIVE and monster.player != null:
		_dive_target = monster.player.global_position

	monster.begin_attack_telegraph(_data)

func exit(_next: String) -> void:
	if _hitbox_active:
		monster.deactivate_attack_hitbox()
		_hitbox_active = false
	monster.end_attack_telegraph()
	if _data != null and _data.exposes_belly_on_recovery:
		monster.close_state_weak_point()

func physics_step(delta: float) -> void:
	if _data == null:
		machine.change_to(monster.default_combat_state())
		return

	_elapsed += delta

	match _data.kind:
		WCAttackData.Kind.MELEE:
			_update_melee(delta)
		WCAttackData.Kind.PROJECTILE:
			_update_projectile(delta)
		WCAttackData.Kind.DIVE:
			_update_dive(delta)
		WCAttackData.Kind.CHARGE:
			_update_charge(delta)
		WCAttackData.Kind.BARRAGE:
			_update_barrage(delta)

	_update_state_weak_points()

	if _elapsed >= _data.total_duration():
		monster.start_cooldown(_data.label, _data.cooldown)
		if monster.should_rest():
			machine.change_to("Exhausted")
		else:
			machine.change_to(monster.default_combat_state())

func _update_melee(delta: float) -> void:
	if not monster.is_on_wall_surface:
		monster.apply_gravity(delta)
	_apply_advance(delta)
	_update_hitbox()
	if not monster.is_on_wall_surface:
		monster.move_and_slide()

func _update_projectile(delta: float) -> void:
	if not monster.is_on_wall_surface:
		monster.apply_gravity(delta)
	monster.velocity.x = move_toward(monster.velocity.x, 0.0, 30.0 * delta)
	monster.velocity.z = move_toward(monster.velocity.z, 0.0, 30.0 * delta)
	if not monster.is_on_wall_surface:
		monster.move_and_slide()

	if _projectile_spawned == 0 and _elapsed >= _data.telegraph_time:
		_spawn_spit(0.0)
		_projectile_spawned = 1
		if _data.exposes_throat:
			pass

func _update_barrage(delta: float) -> void:
	if not monster.is_on_wall_surface:
		monster.apply_gravity(delta)
	monster.velocity.x = move_toward(monster.velocity.x, 0.0, 30.0 * delta)
	monster.velocity.z = move_toward(monster.velocity.z, 0.0, 30.0 * delta)
	if not monster.is_on_wall_surface:
		monster.move_and_slide()

	if _elapsed >= _data.telegraph_time and _projectile_spawned < _data.barrage_count:
		if _elapsed >= _next_barrage_time:
			var index: int = _projectile_spawned
			var count: int = maxi(_data.barrage_count, 1)
			var spread: float = _data.barrage_spread_deg
			var offset_deg: float = 0.0
			if count > 1:
				offset_deg = -spread * 0.5 + spread * (float(index) / float(count - 1))
			_spawn_spit(offset_deg)
			_projectile_spawned += 1
			_next_barrage_time = _elapsed + _data.barrage_delay

func _update_dive(delta: float) -> void:
	if not _dive_started and _elapsed >= _data.telegraph_time:
		_dive_started = true
		monster.clear_wall_cling()
	if _dive_started and not _dive_landed:
		var to_target: Vector3 = _dive_target - monster.global_position
		var step: float = _data.dive_speed * delta
		if to_target.length() <= step + 0.3:
			monster.global_position = _dive_target + Vector3(0, 0.1, 0)
			_dive_landed = true
			_apply_dive_shockwave()
			if _data.exposes_belly_on_recovery:
				monster.open_state_weak_point(monster.belly_post_dive_duration)
		else:
			monster.global_position += to_target.normalized() * step
	elif _dive_landed:
		monster.apply_gravity(delta)
		monster.velocity.x = move_toward(monster.velocity.x, 0.0, 40.0 * delta)
		monster.velocity.z = move_toward(monster.velocity.z, 0.0, 40.0 * delta)
		monster.move_and_slide()

func _update_charge(delta: float) -> void:
	if _elapsed < _data.telegraph_time:
		return
	if _elapsed < _data.active_end():
		if monster.is_on_wall_surface:
			monster.slide_along_wall(_advance_dir, _data.advance_speed, delta)
		else:
			monster.velocity.x = _advance_dir.x * _data.advance_speed
			monster.velocity.z = _advance_dir.z * _data.advance_speed
			monster.apply_gravity(delta)
			monster.move_and_slide()
		_update_hitbox()
	else:
		if not monster.is_on_wall_surface:
			monster.velocity.x = move_toward(monster.velocity.x, 0.0, 40.0 * delta)
			monster.velocity.z = move_toward(monster.velocity.z, 0.0, 40.0 * delta)
			monster.apply_gravity(delta)
			monster.move_and_slide()

func _apply_advance(delta: float) -> void:
	if _data.advance_distance <= 0.0 or _advance_dir.length() < 0.01:
		monster.velocity.x = move_toward(monster.velocity.x, 0.0, 30.0 * delta)
		monster.velocity.z = move_toward(monster.velocity.z, 0.0, 30.0 * delta)
		return
	if _elapsed >= _data.active_start() and _elapsed < _data.active_end():
		var duration: float = maxf(_data.active_time, 0.01)
		var t: float = clampf((_elapsed - _data.active_start()) / duration, 0.0, 1.0)
		var peak_speed: float = 1.5 * _data.advance_distance / duration
		var speed: float = lerpf(peak_speed, 0.0, ease(t, 2.0))
		monster.velocity.x = _advance_dir.x * speed
		monster.velocity.z = _advance_dir.z * speed
	else:
		monster.velocity.x = move_toward(monster.velocity.x, 0.0, 30.0 * delta)
		monster.velocity.z = move_toward(monster.velocity.z, 0.0, 30.0 * delta)

func _update_hitbox() -> void:
	var active: bool = _elapsed >= _data.active_start() and _elapsed < _data.active_end()
	if active and not _hitbox_active:
		monster.activate_attack_hitbox(_data)
		_hitbox_active = true
	elif not active and _hitbox_active:
		monster.deactivate_attack_hitbox()
		_hitbox_active = false

func _update_state_weak_points() -> void:
	if _data.exposes_throat:
		var in_window: bool = _elapsed < _data.active_end()
		monster.set_throat_weak_point(in_window)

func _spawn_spit(offset_deg: float) -> void:
	monster.spawn_acid_spit(_data, offset_deg)

func _apply_dive_shockwave() -> void:
	monster.apply_dive_shockwave(_data.dive_shockwave_radius, _data.dive_shockwave_damage)
