extends MonsterState

@export var duration: float = 2.5

var _elapsed: float = 0.0

func enter(_prev: String) -> void:
	_elapsed = 0.0

func physics_step(delta: float) -> void:
	_elapsed += delta
	monster.apply_gravity(delta)
	monster.velocity.x = move_toward(monster.velocity.x, 0.0, 40.0 * delta)
	monster.velocity.z = move_toward(monster.velocity.z, 0.0, 40.0 * delta)
	monster.move_and_slide()
	if _elapsed >= duration:
		machine.change_to("Chase")
