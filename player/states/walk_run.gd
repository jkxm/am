extends PlayerState

const STUCK_THRESHOLD_SEC: float = 0.5

var _stuck_timer: float = 0.0
var _last_pos: Vector3 = Vector3.ZERO
var _stuck_reported: bool = false
var _last_slide_print: float = 0.0

func enter(_prev_state: String) -> void:
	_stuck_timer = 0.0
	_last_pos = player.global_position
	_stuck_reported = false
	_last_slide_print = 0.0
	print("[WalkRun] enter  pos=(%.2f, %.2f, %.2f)  vel=%.2f  floor=%s  time_scale=%.2f  invuln=%s" % [
		_last_pos.x, _last_pos.y, _last_pos.z,
		player.velocity.length(), str(player.is_on_floor()),
		Engine.time_scale, str(player.invulnerable)
	])

func physics_step(delta: float) -> void:
	var move_input := player.read_move_input()
	if move_input.length() < 0.01:
		machine.change_to("Idle")
		return

	var wants_sprint := Input.is_action_pressed("sprint")
	var can_sprint := wants_sprint and not player.stamina.is_empty()
	if can_sprint:
		player.stamina.drain(delta)

	var target_speed := player.sprint_speed if can_sprint else player.walk_speed
	var direction := player.camera_relative_direction(move_input)
	var target_velocity := direction * target_speed

	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, target_velocity.x, player.ground_accel * delta)
	player.velocity.z = move_toward(player.velocity.z, target_velocity.z, player.ground_accel * delta)
	player.face_direction(direction, delta)
	player.move_and_slide()

	var slides: int = player.get_slide_collision_count()
	if slides > 0:
		var now: float = Time.get_ticks_msec() / 1000.0
		if now - _last_slide_print > 0.4:
			_last_slide_print = now
			var names: Array[String] = []
			for i: int in range(slides):
				var c: KinematicCollision3D = player.get_slide_collision(i)
				if c != null and c.get_collider() != null:
					names.append(c.get_collider().name)
			print("[WalkRun] slides=%d  with=%s  vel=%.2f  target_vel=%.2f  invuln=%s" % [
				slides, str(names), player.velocity.length(), target_velocity.length(), str(player.invulnerable)
			])

	var delta_pos: Vector3 = player.global_position - _last_pos
	delta_pos.y = 0.0
	if target_velocity.length() > 0.5 and delta_pos.length() < 0.01:
		_stuck_timer += delta
		if _stuck_timer > STUCK_THRESHOLD_SEC and not _stuck_reported:
			_stuck_reported = true
			var other: String = "?"
			for i: int in range(slides):
				var col: KinematicCollision3D = player.get_slide_collision(i)
				if col != null and col.get_collider() != null:
					other = col.get_collider().name
					break
			print("[WalkRun] STUCK against %s  slides=%d  target_vel=%.2f  pos=(%.2f, %.2f, %.2f)  time_scale=%.2f  invuln=%s" % [
				other, slides, target_velocity.length(),
				player.global_position.x, player.global_position.y, player.global_position.z,
				Engine.time_scale, str(player.invulnerable)
			])
	else:
		_stuck_timer = 0.0
		_stuck_reported = false
	_last_pos = player.global_position

	if not player.is_on_floor():
		machine.change_to("JumpFall")
		return

	if InputBuffer.consume("jump"):
		player.do_jump()
		machine.change_to("JumpFall")
		return

	if InputBuffer.consume("dodge"):
		if player.stamina.try_spend(player.dodge_stamina_cost):
			machine.change_to("DodgeRoll")
			return

	if InputBuffer.consume("attack"):
		machine.change_to("ChargeAttack")
		return
