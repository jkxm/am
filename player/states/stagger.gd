extends PlayerState

@export var duration: float = 0.45
@export var knockback_horizontal: float = 5.0
@export var knockback_vertical: float = 3.0

var _elapsed: float = 0.0

func enter(_prev_state: String) -> void:
	_elapsed = 0.0
	var dir: Vector3 = player.last_hit_direction
	if dir.length() < 0.01:
		dir = -player.mesh_root.global_transform.basis.z
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length() > 0.01:
		flat = flat.normalized()
	else:
		flat = -player.mesh_root.global_transform.basis.z
	player.velocity.x = flat.x * knockback_horizontal
	player.velocity.z = flat.z * knockback_horizontal
	if player.is_on_floor():
		player.velocity.y = knockback_vertical
	player.face_direction(-flat, 1.0)

func physics_step(delta: float) -> void:
	_elapsed += delta
	player.apply_gravity(delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.ground_accel * 0.7 * delta)
	player.velocity.z = move_toward(player.velocity.z, 0.0, player.ground_accel * 0.7 * delta)
	player.move_and_slide()

	if _elapsed >= duration:
		if player.is_on_floor():
			machine.change_to("WalkRun" if player.read_move_input().length() > 0.01 else "Idle")
		else:
			machine.change_to("JumpFall")
