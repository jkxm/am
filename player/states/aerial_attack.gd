extends PlayerState

@export var landed_recovery_time: float = 0.25
@export var landed_dodge_cancel_start: float = 0.1
@export var aoe_pulse_duration: float = 0.18

var _data: AttackData = null
var _elapsed: float = 0.0
var _hit_connected: bool = false
var _descent_hitbox_active: bool = false
var _landed: bool = false
var _landed_elapsed: float = 0.0
var _aoe_elapsed: float = 0.0
var _aoe_active: bool = false

func enter(_prev_state: String) -> void:
	if player.pending_attack != null:
		_data = player.pending_attack
	else:
		_data = player.heavy_weapon.get_air_attack(0)
	player.pending_attack = null
	_elapsed = 0.0
	_hit_connected = false
	_descent_hitbox_active = false
	_landed = false
	_landed_elapsed = 0.0
	_aoe_elapsed = 0.0
	_aoe_active = false
	player.stamina.drain_amount(_data.stamina_cost)
	player.velocity.x = 0.0
	player.velocity.z = 0.0
	player.velocity.y = -_data.slam_speed
	if player.camera_rig != null:
		player.camera_rig.boost_follow(1.5)

	print("[AerialAttack] enter %s  slam=%.1f  impact_radius=%.1f" % [_data.label, _data.slam_speed, _data.impact_radius])

	if player.heavy_weapon.hitbox.hit_landed.is_connected(_on_hit_landed):
		player.heavy_weapon.hitbox.hit_landed.disconnect(_on_hit_landed)
	player.heavy_weapon.hitbox.hit_landed.connect(_on_hit_landed)

func exit(_next_state: String) -> void:
	if _descent_hitbox_active or _aoe_active:
		player.heavy_weapon.deactivate_hitbox()
		_descent_hitbox_active = false
		_aoe_active = false
	if player.heavy_weapon.hitbox.hit_landed.is_connected(_on_hit_landed):
		player.heavy_weapon.hitbox.hit_landed.disconnect(_on_hit_landed)

func physics_step(delta: float) -> void:
	if _data == null:
		machine.change_to("JumpFall")
		return

	_elapsed += delta

	if not _landed:
		_update_descent_hitbox()
		player.velocity.y = -_data.slam_speed
		player.velocity.x *= 0.7
		player.velocity.z *= 0.7
	else:
		_landed_elapsed += delta
		_update_aoe(delta)
		player.apply_gravity(delta)
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.ground_accel * delta)
		player.velocity.z = move_toward(player.velocity.z, 0.0, player.ground_accel * delta)
	player.move_and_slide()

	if player.is_on_floor() and not _landed:
		_landed = true
		_landed_elapsed = 0.0
		print("[AerialAttack] land t=%.2fs" % _elapsed)
		if player.camera_rig != null:
			player.camera_rig.shake(_data.screen_shake_amplitude)
		Hitstop.pulse(_data.hitstop_ms)
		if _descent_hitbox_active:
			player.heavy_weapon.deactivate_hitbox()
			_descent_hitbox_active = false
		if _data.impact_radius > 0.01:
			player.heavy_weapon.activate_aoe_hitbox(_data, player.global_position + Vector3(0, 0.2, 0))
			_aoe_active = true
			_aoe_elapsed = 0.0

	if _landed:
		if _landed_elapsed >= landed_dodge_cancel_start and _data.has_cancel_window and InputBuffer.consume("dodge"):
			if player.stamina.try_spend(player.dodge_stamina_cost):
				machine.change_to("DodgeRoll")
				return
		if _landed_elapsed >= landed_recovery_time:
			print("[AerialAttack] finish(landed) elapsed=%.2f" % _elapsed)
			_finish()
			return
	elif _elapsed >= 2.0:
		push_warning("AerialAttack timeout elapsed=%.2f (never landed)" % _elapsed)
		_finish()
		return

func _update_descent_hitbox() -> void:
	if not _descent_hitbox_active:
		player.heavy_weapon.activate_hitbox(_data)
		_descent_hitbox_active = true

func _update_aoe(delta: float) -> void:
	if not _aoe_active:
		return
	_aoe_elapsed += delta
	if _aoe_elapsed >= aoe_pulse_duration:
		player.heavy_weapon.deactivate_hitbox()
		_aoe_active = false

func _finish() -> void:
	var move_input: Vector2 = player.read_move_input()
	if player.is_on_floor():
		machine.change_to("WalkRun" if move_input.length() > 0.01 else "Idle")
	else:
		machine.change_to("JumpFall")

func _on_hit_landed(hurtbox: Hurtbox, event: DamageEvent) -> void:
	if _hit_connected:
		return
	_hit_connected = true
	print("[AerialAttack] hit t=%.2fs  target=%s  damage=%.1f" % [_elapsed, hurtbox.name if hurtbox != null else "?", event.amount])
	Hitstop.pulse(event.hitstop_ms)
	if player.camera_rig != null:
		player.camera_rig.shake(event.screen_shake_amplitude)
	var point: Vector3 = hurtbox.global_position if hurtbox != null else player.global_position
	var level: int = _data.charge_level if _data != null else 0
	player.on_landed_hit(point, -event.direction, level)
	var target: Node = hurtbox.owner_ref if hurtbox != null else null
	player.deliver_knockback(target, &"air", point, level)
