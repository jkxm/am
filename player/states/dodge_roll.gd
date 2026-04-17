extends PlayerState

@export var roll_distance: float = 3.0
@export var roll_duration: float = 0.45
@export var iframe_start: float = 0.05
@export var iframe_end: float = 0.32
@export var recovery_lockout: float = 0.12

var _elapsed: float = 0.0
var _direction: Vector3 = Vector3.ZERO

func enter(_prev_state: String) -> void:
	_elapsed = 0.0
	var move_input := player.read_move_input()
	if move_input.length() < 0.01:
		_direction = -player.global_transform.basis.z
	else:
		_direction = player.camera_relative_direction(move_input).normalized()
	player.invulnerable = false

func exit(_next_state: String) -> void:
	player.invulnerable = false

func physics_step(delta: float) -> void:
	_elapsed += delta

	player.invulnerable = _elapsed >= iframe_start and _elapsed <= iframe_end

	var t: float = clampf(_elapsed / roll_duration, 0.0, 1.0)
	var eased: float = ease(t, 2.0)
	var peak_speed: float = 1.5 * roll_distance / roll_duration
	var speed_curve: float = lerpf(peak_speed, 0.0, eased)
	var horizontal: Vector3 = _direction * speed_curve

	player.apply_gravity(delta)
	player.velocity.x = horizontal.x
	player.velocity.z = horizontal.z
	player.face_direction(_direction, delta)
	player.move_and_slide()

	if _elapsed >= roll_duration + recovery_lockout:
		if not player.is_on_floor():
			machine.change_to("JumpFall")
		elif player.read_move_input().length() > 0.01:
			machine.change_to("WalkRun")
		else:
			machine.change_to("Idle")
