class_name WCMenace
extends Node

@export_group("Head Tracking")
@export var head_track_lerp_speed: float = 5.0
@export var head_track_max_yaw_deg: float = 85.0
@export var head_track_max_pitch_deg: float = 55.0

@export_group("Eyes")
@export var eye_offset: Vector3 = Vector3(0.3, 0.12, -0.55)
@export var eye_idle_color: Color = Color(0.9, 0.45, 0.05)
@export var eye_tracking_color: Color = Color(1.0, 0.6, 0.05)
@export var eye_attack_color: Color = Color(1.0, 0.1, 0.0)
@export var eye_spit_color: Color = Color(0.35, 1.0, 0.1)
@export var eye_enraged_color: Color = Color(1.0, 0.0, 0.0)
@export var eye_exhausted_color: Color = Color(0.25, 0.35, 0.6)
@export var eye_idle_energy: float = 0.8
@export var eye_tracking_energy: float = 1.5
@export var eye_attack_energy: float = 3.0
@export var eye_enraged_energy: float = 4.0
@export var eye_range: float = 1.5
@export var eye_lerp_speed: float = 6.0

@export_group("Idle Sway")
@export var idle_sway_amount: float = 0.04
@export var idle_sway_speed: float = 1.4

@export_group("Flinch")
@export var flinch_amount: float = 0.08
@export var flinch_recovery_speed: float = 8.0

@export_group("Phase 3 Twitch")
@export var phase3_vibrate_amount: float = 0.02
@export var phase3_vibrate_frequency: float = 22.0
@export var phase3_flinch_interval: float = 6.0
@export var phase3_eye_flicker: float = 0.4

enum EyeState { IDLE, TRACKING, ATTACK, SPIT, ENRAGED, EXHAUSTED }

var _monster: WallCrawler = null
var _head_node: Node3D = null
var _mesh_root: Node3D = null
var _torso_node: Node3D = null
var _eye_left: OmniLight3D = null
var _eye_right: OmniLight3D = null

var _flinch_offset: Vector3 = Vector3.ZERO
var _mesh_base_position: Vector3 = Vector3.ZERO
var _torso_base_position: Vector3 = Vector3.ZERO
var _eye_state: int = EyeState.IDLE
var _eye_color_current: Color = Color.BLACK
var _eye_energy_current: float = 0.0
var _phase3_flinch_timer: float = 0.0
var _phase3_flinch_pulse: float = 0.0

func setup(monster: WallCrawler) -> void:
	_monster = monster
	_mesh_root = monster.get_node_or_null("MeshRoot") as Node3D
	_head_node = monster.get_node_or_null("MeshRoot/Head") as Node3D
	_torso_node = monster.get_node_or_null("MeshRoot/Torso") as Node3D
	if _mesh_root != null:
		_mesh_base_position = _mesh_root.position
	if _torso_node != null:
		_torso_base_position = _torso_node.position
	_spawn_eyes()
	_phase3_flinch_timer = phase3_flinch_interval

func _spawn_eyes() -> void:
	if _head_node == null:
		return
	_eye_left = _make_eye(Vector3(-eye_offset.x, eye_offset.y, eye_offset.z))
	_eye_right = _make_eye(Vector3(eye_offset.x, eye_offset.y, eye_offset.z))
	_head_node.add_child(_eye_left)
	_head_node.add_child(_eye_right)

func _make_eye(local_pos: Vector3) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = "Eye"
	light.position = local_pos
	light.light_color = eye_idle_color
	light.light_energy = eye_idle_energy
	light.omni_range = eye_range
	return light

func flinch(direction: Vector3) -> void:
	if direction.length() < 0.01:
		return
	_flinch_offset = direction.normalized() * flinch_amount

func _process(delta: float) -> void:
	if _monster == null:
		return
	_update_head_tracking(delta)
	_update_sway(delta)
	_update_phase3_twitch(delta)
	_update_eyes(delta)
	_apply_mesh_offset()

func _apply_mesh_offset() -> void:
	if _mesh_root == null:
		return
	_mesh_root.position = _mesh_base_position + _flinch_offset

func _update_sway(delta: float) -> void:
	if _torso_node == null:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var sway: float = sin(t * idle_sway_speed * TAU) * idle_sway_amount
	_torso_node.position = _torso_base_position + Vector3(sway, 0.0, 0.0)
	_flinch_offset = _flinch_offset.move_toward(Vector3.ZERO, flinch_recovery_speed * delta)

func _update_phase3_twitch(delta: float) -> void:
	if _mesh_root == null:
		return
	if _monster.phase < 3:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var vibrate := Vector3(
		sin(t * phase3_vibrate_frequency * 1.7) * phase3_vibrate_amount,
		sin(t * phase3_vibrate_frequency * 2.1) * phase3_vibrate_amount * 0.5,
		sin(t * phase3_vibrate_frequency * 1.3) * phase3_vibrate_amount,
	)
	_flinch_offset += vibrate * delta * 40.0

	_phase3_flinch_timer -= delta
	if _phase3_flinch_timer <= 0.0:
		_phase3_flinch_timer = phase3_flinch_interval + randf_range(-1.5, 1.5)
		var flinch_dir: Vector3 = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		flinch(flinch_dir)

func _update_head_tracking(delta: float) -> void:
	if _head_node == null or _monster.player == null:
		return
	if _monster.current_state_name() == "Transitioning":
		return
	var to_player: Vector3 = _monster.player.global_position - _head_node.global_position
	if to_player.length() < 0.1:
		return
	var local: Vector3 = _head_node.get_parent().to_local(_monster.player.global_position) - _head_node.position
	if local.length() < 0.1:
		return
	var yaw: float = atan2(local.x, -local.z)
	var pitch: float = atan2(local.y, Vector2(local.x, local.z).length())
	yaw = clampf(yaw, -deg_to_rad(head_track_max_yaw_deg), deg_to_rad(head_track_max_yaw_deg))
	pitch = clampf(pitch, -deg_to_rad(head_track_max_pitch_deg), deg_to_rad(head_track_max_pitch_deg))
	var target_rot: Vector3 = Vector3(-pitch, yaw, 0.0)
	var lerp_factor: float = clampf(head_track_lerp_speed * delta, 0.0, 1.0)
	_head_node.rotation = _head_node.rotation.lerp(target_rot, lerp_factor)

func set_eye_state(state: int) -> void:
	_eye_state = state

func _update_eyes(delta: float) -> void:
	if _eye_left == null or _eye_right == null:
		return
	var target_color: Color = eye_idle_color
	var target_energy: float = eye_idle_energy
	var spit_attack: bool = false
	if _monster.current_state_name() == "Attacking" and _monster.pending_attack != null:
		var kind: int = _monster.pending_attack.kind
		if kind == WCAttackData.Kind.PROJECTILE or kind == WCAttackData.Kind.BARRAGE:
			spit_attack = true
	if _monster.is_enraged:
		target_color = eye_enraged_color
		target_energy = eye_enraged_energy
	elif _monster.is_exhausted:
		target_color = eye_exhausted_color
		target_energy = eye_idle_energy
	elif spit_attack:
		target_color = eye_spit_color
		target_energy = eye_attack_energy
	elif _monster.current_state_name() == "Attacking":
		target_color = eye_attack_color
		target_energy = eye_attack_energy
	elif _monster.player != null:
		target_color = eye_tracking_color
		target_energy = eye_tracking_energy

	var lerp_t: float = clampf(eye_lerp_speed * delta, 0.0, 1.0)
	_eye_color_current = _eye_color_current.lerp(target_color, lerp_t)
	_eye_energy_current = lerpf(_eye_energy_current, target_energy, lerp_t)
	var flicker: float = 0.0
	if _monster.phase >= 3:
		flicker = randf_range(-phase3_eye_flicker, phase3_eye_flicker)
	_eye_left.light_color = _eye_color_current
	_eye_right.light_color = _eye_color_current
	_eye_left.light_energy = maxf(_eye_energy_current + flicker, 0.1)
	_eye_right.light_energy = maxf(_eye_energy_current + flicker, 0.1)
