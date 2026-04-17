extends MonsterState

@export var aggro_range: float = 18.0
@export var look_turn_speed: float = 2.0

func physics_step(delta: float) -> void:
	monster.apply_gravity(delta)
	monster.velocity.x = move_toward(monster.velocity.x, 0.0, 20.0 * delta)
	monster.velocity.z = move_toward(monster.velocity.z, 0.0, 20.0 * delta)
	monster.move_and_slide()

	if monster.player == null:
		return

	var to_player: Vector3 = monster.player.global_position - monster.global_position
	to_player.y = 0.0
	if to_player.length() < aggro_range:
		machine.change_to("Chase")
		return

	if to_player.length() > 0.01:
		monster.face_toward(to_player, delta * look_turn_speed)
