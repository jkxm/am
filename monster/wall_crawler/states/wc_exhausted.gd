extends WCState

@export var duration: float = 2.5

var _elapsed: float = 0.0

func enter(_prev: String) -> void:
	_elapsed = 0.0
	monster.open_state_weak_point(monster.exhaustion_belly_expose_duration)

func exit(_next: String) -> void:
	monster.close_state_weak_point()

func physics_step(delta: float) -> void:
	_elapsed += delta
	if not monster.is_on_wall_surface:
		monster.apply_gravity(delta)
		monster.velocity.x = move_toward(monster.velocity.x, 0.0, 40.0 * delta)
		monster.velocity.z = move_toward(monster.velocity.z, 0.0, 40.0 * delta)
		monster.move_and_slide()
	if _elapsed >= duration:
		machine.change_to(monster.default_combat_state())
