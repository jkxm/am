extends WCState

@export var min_decision_interval: float = 0.5
@export var max_decision_interval: float = 1.5
@export var reposition_chance: float = 0.35
@export var reposition_min_stay: float = 3.5

var _decision_timer: float = 0.0

func enter(_prev: String) -> void:
	_decision_timer = randf_range(min_decision_interval, max_decision_interval) * monster.decision_interval_mult()

func physics_step(delta: float) -> void:
	if monster.player == null:
		machine.change_to("Idle")
		return

	monster.update_wall_cling(delta)
	_decision_timer -= delta
	if _decision_timer <= 0.0:
		_pick_next_action()

func _pick_next_action() -> void:
	if monster.should_transition_to_ground():
		machine.change_to("Transitioning")
		return
	var distance: float = monster.global_position.distance_to(monster.player.global_position)
	var attack: WCAttackData = monster.pick_attack(distance, WCAttackData.Surface.WALL)
	if attack != null:
		monster.pending_attack = attack
		machine.change_to("Attacking")
		return
	if monster._surface_stay_timer >= reposition_min_stay and randf() < reposition_chance:
		monster.pick_new_wall_anchor()
		machine.change_to("Transitioning")
		return
	_decision_timer = randf_range(min_decision_interval, max_decision_interval) * monster.decision_interval_mult()
