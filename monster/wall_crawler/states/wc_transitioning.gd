extends WCState

var _elapsed: float = 0.0
var _duration: float = 1.0
var _start_pos: Vector3 = Vector3.ZERO
var _target_pos: Vector3 = Vector3.ZERO
var _start_basis: Basis = Basis.IDENTITY
var _target_basis: Basis = Basis.IDENTITY
var _next_state: String = "CombatGround"

func enter(_prev: String) -> void:
	_elapsed = 0.0
	_start_pos = monster.global_position
	_start_basis = monster.global_transform.basis

	var info: Dictionary = monster.begin_transition()
	_target_pos = info.get("target_pos", _start_pos)
	_target_basis = info.get("target_basis", _start_basis)
	_duration = info.get("duration", 1.0)
	_next_state = info.get("next_state", "CombatGround")

func physics_step(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / maxf(_duration, 0.01), 0.0, 1.0)
	var eased: float = ease(t, 0.5)
	var pos: Vector3 = _start_pos.lerp(_target_pos, eased)
	var lift: float = sin(t * PI) * 0.8
	pos.y += lift
	var basis: Basis = _start_basis.slerp(_target_basis, eased)
	monster.global_transform = Transform3D(basis, pos)
	monster.velocity = Vector3.ZERO
	if t >= 1.0:
		monster.finish_transition()
		machine.change_to(_next_state)
