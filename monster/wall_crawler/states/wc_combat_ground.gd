extends WCState

@export var leash_range: float = 28.0
@export var acceleration: float = 14.0
@export var preferred_distance: float = 3.5
@export var min_decision_interval: float = 0.5
@export var max_decision_interval: float = 1.2

var _decision_timer: float = 0.0

func enter(_prev: String) -> void:
	_decision_timer = randf_range(min_decision_interval, max_decision_interval) * monster.decision_interval_mult()

func physics_step(delta: float) -> void:
	if monster.player == null:
		machine.change_to("Idle")
		return

	monster.apply_gravity(delta)
	var to_player: Vector3 = monster.player.global_position - monster.global_position
	to_player.y = 0.0
	var distance: float = to_player.length()

	if distance > leash_range:
		machine.change_to("Idle")
		return

	_decision_timer -= delta
	var target_vx: float = 0.0
	var target_vz: float = 0.0
	if distance > 0.01:
		var dir: Vector3 = to_player.normalized()
		var approach: bool = distance > preferred_distance
		var speed_target: float = monster.ground_walk_speed * (1.0 if approach else -0.3)
		target_vx = dir.x * speed_target
		target_vz = dir.z * speed_target
		monster.face_toward(dir, delta * 4.0)

	monster.velocity.x = move_toward(monster.velocity.x, target_vx, acceleration * delta)
	monster.velocity.z = move_toward(monster.velocity.z, target_vz, acceleration * delta)
	monster.move_and_slide()

	if _decision_timer <= 0.0:
		_pick_next_action(distance)

func _pick_next_action(distance: float) -> void:
	if monster.should_transition_to_wall():
		machine.change_to("Transitioning")
		return
	var attack: WCAttackData = monster.pick_attack(distance, WCAttackData.Surface.GROUND)
	if attack != null:
		monster.pending_attack = attack
		machine.change_to("Attacking")
		return
	_decision_timer = randf_range(min_decision_interval, max_decision_interval) * monster.decision_interval_mult()
