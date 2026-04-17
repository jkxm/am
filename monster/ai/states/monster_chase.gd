extends MonsterState

@export var leash_range: float = 22.0
@export var acceleration: float = 12.0

func physics_step(delta: float) -> void:
	if monster.player == null:
		machine.change_to("Idle")
		return

	monster.apply_gravity(delta)
	var to_player: Vector3 = monster.player.global_position - monster.global_position
	to_player.y = 0.0

	if to_player.length() > leash_range:
		machine.change_to("Idle")
		return

	var distance: float = to_player.length()
	var attack_data: MonsterAttackData = monster.pick_attack(distance)
	if attack_data != null:
		monster.pending_attack = attack_data
		machine.change_to("Attack")
		return

	var target_vx: float = 0.0
	var target_vz: float = 0.0
	if distance > 0.01:
		var dir: Vector3 = to_player.normalized()
		target_vx = dir.x * monster.chase_speed
		target_vz = dir.z * monster.chase_speed
		monster.face_toward(dir, delta * 4.0)
	monster.velocity.x = move_toward(monster.velocity.x, target_vx, acceleration * delta)
	monster.velocity.z = move_toward(monster.velocity.z, target_vz, acceleration * delta)
	monster.move_and_slide()
