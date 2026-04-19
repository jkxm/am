extends PlayerState

@export var min_duration: float = 0.25
@export var grounded_recovery: float = 0.4
@export var knockback_horizontal: float = 4.0
@export var airborne_downforce: float = 12.0
@export var airborne_gravity_multiplier: float = 1.6
@export var wall_kickoff: float = 2.5
@export var max_airborne_time: float = 2.5

var _elapsed: float = 0.0
var _grounded_timer: float = 0.0
var _was_airborne: bool = false

func enter(_prev_state: String) -> void:
	_elapsed = 0.0
	_grounded_timer = 0.0
	_was_airborne = not player.is_on_floor()

	var dir: Vector3 = player.last_hit_direction
	if dir.length() < 0.01:
		dir = -player.mesh_root.global_transform.basis.z
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length() > 0.01:
		flat = flat.normalized()
	else:
		flat = -player.mesh_root.global_transform.basis.z

	player.velocity.x = flat.x * knockback_horizontal
	player.velocity.z = flat.z * knockback_horizontal
	if _was_airborne:
		player.velocity.y = -airborne_downforce
	else:
		player.velocity.y = 0.0
	player.face_direction(-flat, 1.0)

	var prev_ctx: String = _prev_state
	if prev_ctx in ["WallRun", "WallCling", "WallDash", "WallJump", "ChargeWallAttack"]:
		var normal: Vector3 = Vector3.ZERO
		if player.wall_detector.has_wall():
			normal = player.wall_detector.wall_normal()
		if normal.length() > 0.01:
			player.velocity += normal * wall_kickoff

func physics_step(delta: float) -> void:
	_elapsed += delta

	var airborne: bool = not player.is_on_floor()
	if airborne:
		player.velocity.y = maxf(player.velocity.y - player.gravity * airborne_gravity_multiplier * delta, -player.terminal_velocity * 1.3)
	else:
		if player.velocity.y < 0.0:
			player.velocity.y = -1.0

	player.velocity.x = move_toward(player.velocity.x, 0.0, player.ground_accel * 0.6 * delta)
	player.velocity.z = move_toward(player.velocity.z, 0.0, player.ground_accel * 0.6 * delta)
	player.move_and_slide()

	if player.is_on_floor():
		_grounded_timer += delta

	var grounded_enough: bool = _grounded_timer >= grounded_recovery
	var min_done: bool = _elapsed >= min_duration
	var airborne_timeout: bool = _elapsed >= max_airborne_time

	if player.is_on_floor() and min_done and grounded_enough:
		machine.change_to("WalkRun" if player.read_move_input().length() > 0.01 else "Idle")
		return
	if airborne_timeout and player.is_on_floor():
		machine.change_to("Idle")
		return
