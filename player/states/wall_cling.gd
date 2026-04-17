extends PlayerState

@export var stick_force: float = 8.0
@export var release_if_no_wall_time: float = 0.1

var _no_wall_timer: float = 0.0

func enter(_prev_state: String) -> void:
	player.velocity = Vector3.ZERO
	player.is_vulnerable = true
	_no_wall_timer = 0.0

func exit(_next_state: String) -> void:
	player.is_vulnerable = false

func physics_step(delta: float) -> void:
	if player.is_on_floor():
		machine.change_to("WalkRun" if player.read_move_input().length() > 0.01 else "Idle")
		return

	if not player.wall_detector.has_wall():
		_no_wall_timer += delta
		if _no_wall_timer >= release_if_no_wall_time:
			machine.change_to("JumpFall")
			return
	else:
		_no_wall_timer = 0.0

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

	var move_input := player.read_move_input()
	if move_input.length() > 0.01 and not player.stamina.is_empty():
		machine.change_to("WallRun")
		return

	var wall_normal: Vector3 = player.wall_detector.wall_normal()
	var stick: Vector3 = -wall_normal * stick_force
	player.velocity = Vector3.ZERO
	player.velocity.x = stick.x * delta
	player.velocity.z = stick.z * delta
	player.move_and_slide()
