extends PlayerState

@export var dash_distance: float = 3.5
@export var dash_duration: float = 0.22
@export var iframe_start: float = 0.04
@export var iframe_end: float = 0.12
@export var recovery_lockout: float = 0.08
@export var hold_gravity: bool = false

var _elapsed: float = 0.0
var _direction: Vector3 = Vector3.ZERO

func enter(_prev_state: String) -> void:
	_elapsed = 0.0
	var move_input := player.read_move_input()
	if move_input.length() < 0.01:
		_direction = -player.mesh_root.global_transform.basis.z
	else:
		_direction = player.camera_relative_direction(move_input).normalized()
	player.invulnerable = false

func exit(_next_state: String) -> void:
	player.invulnerable = false

func physics_step(delta: float) -> void:
	_elapsed += delta
	player.invulnerable = _elapsed >= iframe_start and _elapsed <= iframe_end

	var t: float = clampf(_elapsed / dash_duration, 0.0, 1.0)
	var eased: float = ease(t, 2.0)
	var peak_speed: float = 1.5 * dash_distance / dash_duration
	var speed_curve: float = lerpf(peak_speed, 0.0, eased)
	var horizontal: Vector3 = _direction * speed_curve

	if hold_gravity:
		player.apply_gravity(delta)
	else:
		player.velocity.y = 0.0
	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.z
	if _direction.length() > 0.01:
		player.face_direction(_direction, delta)
	player.move_and_slide()

	if _elapsed >= dash_duration + recovery_lockout:
		if player.is_on_floor():
			machine.change_to("WalkRun" if player.read_move_input().length() > 0.01 else "Idle")
		elif player.wall_detector.has_wall() and player.read_move_input().length() > 0.01 and not player.stamina.is_empty():
			machine.change_to("WallRun")
		else:
			machine.change_to("JumpFall")
