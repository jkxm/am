extends PlayerState

const STUCK_TIMEOUT: float = 0.5

var _entered_at: float = 0.0
var _last_pos: Vector3 = Vector3.ZERO
var _stuck_reported: bool = false
var _stuck_timer: float = 0.0

func enter(_prev_state: String) -> void:
	_entered_at = Time.get_ticks_msec() / 1000.0
	_last_pos = player.global_position
	_stuck_reported = false
	_stuck_timer = 0.0
	print("[Idle] enter  pos=(%.2f, %.2f, %.2f)  vel=%.2f  floor=%s  time_scale=%.2f  invuln=%s" % [
		_last_pos.x, _last_pos.y, _last_pos.z,
		player.velocity.length(), str(player.is_on_floor()),
		Engine.time_scale, str(player.invulnerable)
	])

func physics_step(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_ground_friction(delta)
	player.move_and_slide()

	var slides: int = player.get_slide_collision_count()
	if slides > 0 and not _stuck_reported:
		var names: Array[String] = []
		for i: int in range(slides):
			var c: KinematicCollision3D = player.get_slide_collision(i)
			if c != null and c.get_collider() != null:
				names.append(c.get_collider().name)
		print("[Idle] slide collisions=%d  with=%s" % [slides, str(names)])

	var move_input: Vector2 = player.read_move_input()
	if move_input.length() > 0.01:
		var delta_pos: Vector3 = player.global_position - _last_pos
		delta_pos.y = 0.0
		if delta_pos.length() < 0.005:
			_stuck_timer += delta
			if _stuck_timer > STUCK_TIMEOUT and not _stuck_reported:
				_stuck_reported = true
				print("[Idle] STUCK input=(%.2f, %.2f)  pos=(%.2f, %.2f, %.2f)  time_scale=%.2f  slides=%d" % [
					move_input.x, move_input.y,
					player.global_position.x, player.global_position.y, player.global_position.z,
					Engine.time_scale, slides
				])
		else:
			_stuck_timer = 0.0
			_stuck_reported = false

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

	if player.read_move_input().length() > 0.01:
		machine.change_to("WalkRun")

	_last_pos = player.global_position
