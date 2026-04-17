extends MonsterState

var _data: MonsterAttackData = null
var _elapsed: float = 0.0
var _hitbox_active: bool = false
var _advance_direction: Vector3 = Vector3.ZERO

func enter(_prev: String) -> void:
	_data = monster.pending_attack
	monster.pending_attack = null
	_elapsed = 0.0
	_hitbox_active = false

	if _data == null:
		machine.change_to("Chase")
		return

	if monster.player != null:
		var to_player: Vector3 = monster.player.global_position - monster.global_position
		to_player.y = 0.0
		if to_player.length() > 0.01:
			_advance_direction = to_player.normalized()
			monster.face_toward(_advance_direction, 1.0)
	monster.begin_attack_telegraph(_data)

func exit(_next: String) -> void:
	if _hitbox_active:
		monster.deactivate_attack_hitbox()
		_hitbox_active = false
	monster.end_attack_telegraph()

func physics_step(delta: float) -> void:
	if _data == null:
		machine.change_to("Chase")
		return

	_elapsed += delta
	monster.apply_gravity(delta)
	_apply_advance(delta)
	_update_hitbox()
	monster.move_and_slide()

	if _elapsed >= _data.total_duration():
		monster.start_cooldown(_data.label, _data.cooldown)
		if monster.should_rest():
			machine.change_to("Exhausted")
		else:
			machine.change_to("Chase")

func _apply_advance(delta: float) -> void:
	if _data.advance_distance <= 0.0 or _advance_direction.length() < 0.01:
		monster.velocity.x = move_toward(monster.velocity.x, 0.0, 30.0 * delta)
		monster.velocity.z = move_toward(monster.velocity.z, 0.0, 30.0 * delta)
		return
	if _elapsed >= _data.active_start() and _elapsed < _data.active_end():
		var duration: float = maxf(_data.active_time, 0.01)
		var t: float = clampf((_elapsed - _data.active_start()) / duration, 0.0, 1.0)
		var peak_speed: float = 1.5 * _data.advance_distance / duration
		var speed: float = lerpf(peak_speed, 0.0, ease(t, 2.0))
		monster.velocity.x = _advance_direction.x * speed
		monster.velocity.z = _advance_direction.z * speed
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
