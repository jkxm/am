extends WCState

@export var max_velocity: float = 18.0
@export var lift_per_horizontal_meter: float = 0.35
@export var lift_min: float = 0.8
@export var lift_max: float = 6.0
@export var snap_distance: float = 1.0

var _elapsed: float = 0.0
var _duration: float = 1.0
var _start_pos: Vector3 = Vector3.ZERO
var _target_pos: Vector3 = Vector3.ZERO
var _start_basis: Basis = Basis.IDENTITY
var _target_basis: Basis = Basis.IDENTITY
var _next_state: String = "CombatGround"
var _lift_amount: float = 0.8

func enter(_prev: String) -> void:
	_elapsed = 0.0
	_start_pos = monster.global_position
	_start_basis = monster.global_transform.basis

	var info: Dictionary = monster.begin_transition()
	_target_pos = info.get("target_pos", _start_pos)
	_target_basis = info.get("target_basis", _start_basis)
	_duration = info.get("duration", 1.0)
	_next_state = info.get("next_state", "CombatGround")

	var horizontal: float = Vector2(_target_pos.x - _start_pos.x, _target_pos.z - _start_pos.z).length()
	_lift_amount = clampf(horizontal * lift_per_horizontal_meter, lift_min, lift_max)

func physics_step(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / maxf(_duration, 0.01), 0.0, 1.0)
	var eased: float = ease(t, 0.5)
	var desired_pos: Vector3 = _start_pos.lerp(_target_pos, eased)
	desired_pos.y += sin(t * PI) * _lift_amount

	var displacement: Vector3 = desired_pos - monster.global_position
	var vel: Vector3 = displacement / maxf(delta, 0.001)
	if vel.length() > max_velocity:
		vel = vel.normalized() * max_velocity
	monster.velocity = vel

	monster.global_transform.basis = _start_basis.slerp(_target_basis, eased)
	monster.move_and_slide()

	if t >= 1.0:
		var remaining: float = monster.global_position.distance_to(_target_pos)
		if remaining <= snap_distance:
			monster.global_position = _target_pos
		monster.velocity = Vector3.ZERO
		monster.finish_transition()
		machine.change_to(_next_state)
