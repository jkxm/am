extends PlayerState

@export var wall_mount_input_dot: float = 0.3

func physics_step(delta: float) -> void:
	var move_input := player.read_move_input()
	var direction := player.camera_relative_direction(move_input)
	var target_velocity := direction * player.walk_speed

	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, target_velocity.x, player.air_accel * delta)
	player.velocity.z = move_toward(player.velocity.z, target_velocity.z, player.air_accel * delta)
	if direction.length() > 0.01:
		player.face_direction(direction, delta)
	player.move_and_slide()

	if player.is_on_floor():
		if player.read_move_input().length() > 0.01:
			machine.change_to("WalkRun")
		else:
			machine.change_to("Idle")
		return

	if InputBuffer.consume("dodge"):
		if player.stamina.try_spend(player.dodge_stamina_cost):
			machine.change_to("AirDash")
			return

	if InputBuffer.consume("attack"):
		machine.change_to("ChargeAttack")
		return

	if player.wall_detector.has_wall() and not player.stamina.is_empty():
		var wall_normal: Vector3 = player.wall_detector.wall_normal()
		if direction.length() > 0.01 and direction.dot(-wall_normal) >= wall_mount_input_dot:
			machine.change_to("WallRun")
			return
