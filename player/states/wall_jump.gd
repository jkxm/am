extends PlayerState

@export var vertical_launch: float = 7.0
@export var horizontal_launch: float = 6.5
@export var lockout_duration: float = 0.18

var _elapsed: float = 0.0
var _launch_normal: Vector3 = Vector3.ZERO

func enter(_prev_state: String) -> void:
	_elapsed = 0.0
	if player.wall_detector.has_wall():
		_launch_normal = player.wall_detector.wall_normal()
	else:
		_launch_normal = -player.mesh_root.global_transform.basis.z
	var launch := _launch_normal * horizontal_launch
	player.velocity.x = launch.x
	player.velocity.z = launch.z
	player.velocity.y = vertical_launch
	player.face_direction(_launch_normal, 1.0)

func physics_step(delta: float) -> void:
	_elapsed += delta

	var move_input := player.read_move_input()
	var direction := player.camera_relative_direction(move_input)

	player.apply_gravity(delta)
	if direction.length() > 0.01:
		player.velocity.x = move_toward(player.velocity.x, direction.x * player.walk_speed, player.air_accel * delta)
		player.velocity.z = move_toward(player.velocity.z, direction.z * player.walk_speed, player.air_accel * delta)
		player.face_direction(direction, delta)
	player.move_and_slide()

	if _elapsed < lockout_duration:
		return

	if player.is_on_floor():
		machine.change_to("WalkRun" if player.read_move_input().length() > 0.01 else "Idle")
		return

	if InputBuffer.consume("dodge"):
		if player.stamina.try_spend(player.dodge_stamina_cost):
			machine.change_to("AirDash")
			return

	machine.change_to("JumpFall")
