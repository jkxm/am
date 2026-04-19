class_name YBotAnimator
extends Node3D

const BOT_SCENE_PATH: String = "res://assets/Y Bot.fbx"

const ANIM_SOURCES: Dictionary = {
	"idle": "res://assets/Warrior Idle.fbx",
	"gs_walk": "res://assets/Great Sword Walk.fbx",
	"gs_run": "res://assets/Great Sword Run.fbx",
	"run": "res://assets/Running.fbx",
	"wall_run": "res://assets/Wall Run.fbx",
	"gs_attack": "res://assets/great sword slash.fbx",
	"gs_cast": "res://assets/great sword casting.fbx",
	"gs_slide_attack": "res://assets/Great Sword Slide Attack.fbx",
	"gs_jump": "res://assets/Great Sword Jump Attack.fbx",
	"gs_impact": "res://assets/Great Sword Impact.fbx",
	"fall": "res://assets/Falling Idle.fbx",
	"fall_land": "res://assets/Falling To Landing.fbx",
	"dodge_roll": "res://assets/Sprinting Forward Roll.fbx",
}

# Fraction of each attack clip that is "windup" — the point where the pose
# freezes while charging and resumes from on release.
const HOLD_FRACTIONS: Dictionary = {
	"gs_attack": 0.35,
	"gs_cast": 0.40,
	"gs_slide_attack": 0.30,
	"gs_jump": 0.35,
}

@export var model_scale: float = 1.0
@export var model_y_offset: float = 0.0
@export var model_yaw_deg: float = 180.0
@export var crossfade_seconds: float = 0.08

@export var charge_buildup_seconds: float = 0.45
@export var release_recovery_weight: float = 0.6
@export var run_speed_threshold: float = 6.0
@export var landing_from_air_threshold: float = 0.3

@export_group("Greatsword")
@export var sword_bone_name: String = "mixamorig_RightHand"
@export var sword_grip_position: Vector3 = Vector3(0.0, 0.1, 0.0)
@export var sword_grip_rotation_deg: Vector3 = Vector3(0.0, 0.0, 90.0)
@export var sword_blade_size: Vector3 = Vector3(0.15, 1.5, 0.08)
@export var sword_crossguard_size: Vector3 = Vector3(0.4, 0.05, 0.15)
@export var sword_handle_size: Vector3 = Vector3(0.08, 0.25, 0.08)
@export var sword_material_color: Color = Color(0.78, 0.82, 0.88, 1.0)

@export_group("Charge Feedback")
@export var charge_glow_color: Color = Color(1.0, 0.55, 0.15, 1.0)
@export var charge_glow_l0_color: Color = Color(1.0, 0.9, 0.3, 1.0)
@export var charge_glow_l1_color: Color = Color(1.0, 0.95, 0.2, 1.0)
@export var charge_glow_l2_color: Color = Color(1.0, 0.5, 0.05, 1.0)
@export var charge_glow_l3_color: Color = Color(1.0, 0.15, 0.05, 1.0)
@export var charge_glow_level_energy: PackedFloat32Array = PackedFloat32Array([0.0, 1.5, 3.0, 5.0])
@export var charge_glow_level_radius: PackedFloat32Array = PackedFloat32Array([0.5, 1.0, 1.6, 2.2])
@export var charge_glow_lerp_speed: float = 8.0
@export var charge_glow_pulse_speed: float = 4.0
@export var charge_glow_pulse_amp: float = 1.0
@export var charge_glow_release_spike: float = 2.0
@export var charge_vibrate_intensity: float = 0.015
@export var charge_vibrate_frequency: float = 28.0
@export var charge_vignette_l2: float = 0.15
@export var charge_vignette_l3: float = 0.3
@export var charge_aberration_l3: float = 0.003
@export var charge_vignette_color: Color = Color(0.02, 0.0, 0.0, 1.0)

@export var player_path: NodePath = NodePath("..")
@export var state_machine_path: NodePath = NodePath("../../StateMachine")

var player: Player = null
var state_machine: PlayerStateMachine = null
var bot_instance: Node3D = null
var skeleton: Skeleton3D = null
var anim_player: AnimationPlayer = null

var _current_key: String = ""
var _current_state: String = ""
var _charge_clip_key: String = ""
var _charge_hold_time: float = 0.0
var _holding_at_charge_point: bool = false

var _was_airborne: bool = false
var _landing_play_timer: float = 0.0

var _sword_light: OmniLight3D = null
var _sword_blade_mat: StandardMaterial3D = null
var _charge_light_energy: float = 0.0
var _charge_color_current: Color = Color(1.0, 0.9, 0.3, 1.0)
var _charge_light_radius: float = 0.5
var _charge_pulse_time: float = 0.0
var _release_flash_timer: float = 0.0
var _model_base_offset: Vector3 = Vector3.ZERO
var _was_charging: bool = false

func _ready() -> void:
	_spawn_bot()
	if bot_instance == null:
		push_warning("YBotAnimator: failed to spawn Y Bot scene")
		return
	_load_animations()
	_play_key("idle")
	call_deferred("_connect_state_machine")

func _connect_state_machine() -> void:
	var p: Node = get_node_or_null(player_path)
	if p != null and p is Player:
		player = p as Player
	var sm: Node = get_node_or_null(state_machine_path)
	if sm != null and sm is PlayerStateMachine:
		state_machine = sm as PlayerStateMachine
	if state_machine == null:
		push_warning("YBotAnimator: state_machine not found at %s" % state_machine_path)
		return
	if not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)
	_on_state_changed(state_machine.current_name())

func _spawn_bot() -> void:
	var scene: PackedScene = load(BOT_SCENE_PATH) as PackedScene
	if scene == null:
		return
	bot_instance = scene.instantiate() as Node3D
	add_child(bot_instance)
	bot_instance.scale = Vector3.ONE * model_scale
	bot_instance.position.y = model_y_offset
	bot_instance.rotation.y = deg_to_rad(model_yaw_deg)
	skeleton = _find_node(bot_instance, "Skeleton3D") as Skeleton3D
	anim_player = _find_animation_player(bot_instance)
	_attach_greatsword()

func _attach_greatsword() -> void:
	if skeleton == null:
		return
	var bone_idx: int = skeleton.find_bone(sword_bone_name)
	if bone_idx < 0:
		push_warning("YBotAnimator: sword bone not found: %s" % sword_bone_name)
		return
	var attach := BoneAttachment3D.new()
	attach.name = "GreatswordAttach"
	attach.bone_name = sword_bone_name
	attach.bone_idx = bone_idx
	skeleton.add_child(attach)

	var grip := Node3D.new()
	grip.name = "Grip"
	grip.position = sword_grip_position
	grip.rotation = Vector3(
		deg_to_rad(sword_grip_rotation_deg.x),
		deg_to_rad(sword_grip_rotation_deg.y),
		deg_to_rad(sword_grip_rotation_deg.z),
	)
	attach.add_child(grip)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = sword_material_color
	mat.metallic = 0.65
	mat.roughness = 0.35

	var blade := CSGBox3D.new()
	blade.name = "Blade"
	blade.size = sword_blade_size
	blade.position = Vector3(0.0, sword_blade_size.y * 0.5, 0.0)
	blade.material = mat
	grip.add_child(blade)
	_sword_blade_mat = mat

	_sword_light = OmniLight3D.new()
	_sword_light.name = "ChargeGlow"
	_sword_light.light_color = charge_glow_color
	_sword_light.light_energy = 0.0
	_sword_light.omni_range = 0.5
	_sword_light.position = Vector3(0.0, sword_blade_size.y * 0.4, 0.0)
	grip.add_child(_sword_light)

	var guard_mat := StandardMaterial3D.new()
	guard_mat.albedo_color = Color(0.45, 0.42, 0.38, 1.0)
	guard_mat.metallic = 0.8
	guard_mat.roughness = 0.4

	var crossguard := CSGBox3D.new()
	crossguard.name = "Crossguard"
	crossguard.size = sword_crossguard_size
	crossguard.position = Vector3(0.0, 0.0, 0.0)
	crossguard.material = guard_mat
	grip.add_child(crossguard)

	var handle_mat := StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.25, 0.18, 0.12, 1.0)
	handle_mat.roughness = 0.85

	var handle := CSGBox3D.new()
	handle.name = "Handle"
	handle.size = sword_handle_size
	handle.position = Vector3(0.0, -sword_handle_size.y * 0.5, 0.0)
	handle.material = handle_mat
	grip.add_child(handle)

func _load_animations() -> void:
	if anim_player == null:
		return
	var lib := AnimationLibrary.new()
	for key in ANIM_SOURCES.keys():
		var path: String = ANIM_SOURCES[key]
		var scene: PackedScene = load(path) as PackedScene
		if scene == null:
			push_warning("YBotAnimator: missing anim scene %s" % path)
			continue
		var src_root: Node = scene.instantiate()
		var src_ap: AnimationPlayer = _find_animation_player(src_root)
		if src_ap != null:
			for anim_name in src_ap.get_animation_list():
				var src_anim: Animation = src_ap.get_animation(anim_name)
				if src_anim == null:
					continue
				var copy: Animation = src_anim.duplicate() as Animation
				_strip_hips_position_track(copy)
				if key in ["idle", "run", "wall_run", "gs_walk", "gs_run", "fall"]:
					copy.loop_mode = Animation.LOOP_LINEAR
				else:
					copy.loop_mode = Animation.LOOP_NONE
				lib.add_animation(StringName(key), copy)
				break
		src_root.queue_free()
	if anim_player.has_animation_library(&"mix"):
		anim_player.remove_animation_library(&"mix")
	anim_player.add_animation_library(&"mix", lib)

func _strip_hips_position_track(anim: Animation) -> void:
	for i in range(anim.get_track_count() - 1, -1, -1):
		if anim.track_get_type(i) != Animation.TYPE_POSITION_3D:
			continue
		var p: String = String(anim.track_get_path(i))
		if p.ends_with(":mixamorig_Hips") or p.ends_with("mixamorig_Hips"):
			anim.remove_track(i)

func _process(delta: float) -> void:
	_update_charge_animation_hold()
	_update_charge_feedback(delta)
	_process_landing(delta)
	_update_locomotion_speed()

func _update_locomotion_speed() -> void:
	if _current_state != "WalkRun" or player == null or anim_player == null:
		return
	var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	var target: String = "gs_run" if speed > run_speed_threshold else "gs_walk"
	if _current_key != target:
		_play_key(target)

func _update_charge_animation_hold() -> void:
	if anim_player == null:
		return
	if _current_state != "ChargeAttack":
		return
	if _holding_at_charge_point:
		return
	if _current_key != _charge_clip_key:
		return
	if anim_player.current_animation_position >= _charge_hold_time:
		anim_player.seek(_charge_hold_time, true)
		anim_player.speed_scale = 0.0
		_holding_at_charge_point = true

func _update_charge_feedback(delta: float) -> void:
	var se: ScreenEffects = ScreenEffects.get_instance()
	if _current_state == "ChargeAttack" and state_machine != null:
		_was_charging = true
		var level: int = _charge_state_level()
		var target_energy: float = charge_glow_level_energy[clampi(level, 0, charge_glow_level_energy.size() - 1)]
		var target_radius: float = charge_glow_level_radius[clampi(level, 0, charge_glow_level_radius.size() - 1)]
		var target_color: Color = _charge_color_for_level(level)
		if level >= 3:
			_charge_pulse_time += delta * charge_glow_pulse_speed
			target_energy += sin(_charge_pulse_time) * charge_glow_pulse_amp
		var color_lerp_t: float = clampf(charge_glow_lerp_speed * delta, 0.0, 1.0)
		_charge_color_current = _charge_color_current.lerp(target_color, color_lerp_t)
		if _sword_light != null:
			_charge_light_energy = lerpf(_charge_light_energy, target_energy, color_lerp_t)
			_charge_light_radius = lerpf(_charge_light_radius, target_radius, color_lerp_t)
			_sword_light.light_energy = _charge_light_energy
			_sword_light.omni_range = _charge_light_radius
			_sword_light.light_color = _charge_color_current
		if _sword_blade_mat != null:
			if level > 0:
				_sword_blade_mat.emission_enabled = true
				_sword_blade_mat.emission = _charge_color_current
				_sword_blade_mat.emission_energy_multiplier = minf(_charge_light_energy * 0.35, 1.8)
			else:
				_sword_blade_mat.emission_enabled = false
				_sword_blade_mat.emission_energy_multiplier = 0.0
		if bot_instance != null and level >= 3:
			var t: float = Time.get_ticks_msec() / 1000.0
			var shake := Vector3(
				sin(t * charge_vibrate_frequency * 1.7) * charge_vibrate_intensity,
				sin(t * charge_vibrate_frequency * 2.3) * charge_vibrate_intensity * 0.6,
				sin(t * charge_vibrate_frequency * 1.1) * charge_vibrate_intensity,
			)
			bot_instance.position = _model_base_offset + shake
		elif bot_instance != null:
			bot_instance.position = _model_base_offset
		if se != null:
			if level >= 3:
				se.set_vignette(charge_vignette_l3, charge_vignette_color)
				se.spike_aberration(charge_aberration_l3)
			elif level >= 2:
				se.set_vignette(charge_vignette_l2, charge_vignette_color)
			else:
				se.set_vignette(0.0, charge_vignette_color)
	else:
		if _was_charging:
			_was_charging = false
			if _sword_light != null:
				_sword_light.light_energy = _charge_light_energy * charge_glow_release_spike
			_release_flash_timer = 0.15
			if bot_instance != null:
				bot_instance.position = _model_base_offset
			if se != null:
				se.set_vignette(0.0, charge_vignette_color)
		if _release_flash_timer > 0.0:
			_release_flash_timer = maxf(0.0, _release_flash_timer - delta)
			if _sword_light != null:
				var t: float = _release_flash_timer / 0.15
				_sword_light.light_energy = lerpf(0.0, _charge_light_energy * charge_glow_release_spike, t)
		else:
			if _sword_light != null and _sword_light.light_energy > 0.001:
				_sword_light.light_energy = lerpf(_sword_light.light_energy, 0.0, clampf(charge_glow_lerp_speed * delta, 0.0, 1.0))
				if _sword_light.light_energy < 0.05:
					_sword_light.light_energy = 0.0
			_charge_light_energy = 0.0
			if _sword_blade_mat != null and _sword_blade_mat.emission_enabled:
				_sword_blade_mat.emission_energy_multiplier = maxf(0.0, _sword_blade_mat.emission_energy_multiplier - charge_glow_lerp_speed * delta * 2.0)
				if _sword_blade_mat.emission_energy_multiplier < 0.02:
					_sword_blade_mat.emission_enabled = false
					_sword_blade_mat.emission_energy_multiplier = 0.0
			_charge_color_current = charge_glow_color

func _charge_color_for_level(level: int) -> Color:
	match level:
		0: return charge_glow_l0_color
		1: return charge_glow_l1_color
		2: return charge_glow_l2_color
		_: return charge_glow_l3_color

func _charge_state_level() -> int:
	if state_machine == null:
		return 0
	var cur: Node = state_machine._current
	if cur == null:
		return 0
	if cur.has_method("charge_level"):
		return int(cur.call("charge_level"))
	if "_level" in cur:
		var lvl: Variant = cur.get("_level")
		if typeof(lvl) == TYPE_INT:
			return lvl as int
	return 0

func _on_state_changed(state: String) -> void:
	var prev_state: String = _current_state
	_current_state = state
	if prev_state == "ChargeAttack" and state != "ChargeAttack":
		pass
	var just_landed: bool = _was_airborne and _is_grounded_state(state)
	if _is_airborne_state(state):
		_was_airborne = true
	elif _is_grounded_state(state):
		_was_airborne = false

	match state:
		"Idle":
			_exit_charge_hold()
			if just_landed:
				_play_landing()
			else:
				_play_key("idle")
		"WalkRun":
			_exit_charge_hold()
			_play_locomotion()
		"JumpFall":
			_exit_charge_hold()
			_play_key("fall")
		"AirDash":
			_exit_charge_hold()
			_play_key("dodge_roll", 1.6)
		"WallRun":
			_exit_charge_hold()
			_play_key("wall_run")
		"WallCling":
			_exit_charge_hold()
			_play_key("idle")
		"WallJump":
			_exit_charge_hold()
			_play_key("fall")
		"WallDash":
			_exit_charge_hold()
			_play_key("dodge_roll", 1.4)
		"DodgeRoll":
			_exit_charge_hold()
			_play_key("dodge_roll", 1.2)
		"ChargeAttack":
			_start_charge_hold(_charge_clip_for_context())
		"Attack":
			_start_attack_release("gs_attack", prev_state)
		"ChargeWallAttack":
			_start_attack_release("gs_slide_attack", prev_state)
		"AerialAttack":
			_start_attack_release("gs_jump", prev_state)
		"Stagger":
			_exit_charge_hold()
			_play_key("gs_impact", 1.2, true)
		_:
			_exit_charge_hold()
			_play_key("idle")

func _is_airborne_state(s: String) -> bool:
	return s == "JumpFall" or s == "AirDash" or s == "WallJump" or s == "AerialAttack"

func _is_grounded_state(s: String) -> bool:
	return s == "Idle" or s == "WalkRun"

func _play_locomotion() -> void:
	if player == null:
		_play_key("gs_walk")
		return
	var speed: float = Vector2(player.velocity.x, player.velocity.z).length()
	var key: String = "gs_run" if speed > run_speed_threshold else "gs_walk"
	_play_key(key)

func _play_landing() -> void:
	if anim_player == null or not anim_player.has_animation(&"mix/fall_land"):
		_play_key("idle")
		return
	_play_key("fall_land", 1.0, true)
	_landing_play_timer = landing_from_air_threshold

func _process_landing(delta: float) -> void:
	if _landing_play_timer <= 0.0:
		return
	_landing_play_timer -= delta
	if _landing_play_timer <= 0.0:
		if _current_state == "Idle":
			_play_key("idle")
		elif _current_state == "WalkRun":
			_play_locomotion()

func _charge_clip_for_context() -> String:
	if player == null:
		return "gs_attack"
	if not player.is_on_floor():
		return "gs_jump"
	if player.is_on_wall():
		return "gs_slide_attack"
	return "gs_attack"

func _start_charge_hold(clip_key: String) -> void:
	var clip: Animation = _get_clip(clip_key)
	if clip == null:
		return
	var hold_frac: float = HOLD_FRACTIONS.get(clip_key, 0.35)
	_charge_clip_key = clip_key
	_charge_hold_time = clip.length * hold_frac
	_holding_at_charge_point = false
	var buildup_speed: float = _charge_hold_time / maxf(charge_buildup_seconds, 0.01)
	_play_full(clip_key, buildup_speed, true)

func _exit_charge_hold() -> void:
	_holding_at_charge_point = false
	_charge_clip_key = ""
	_charge_hold_time = 0.0
	if anim_player != null and anim_player.speed_scale == 0.0:
		anim_player.speed_scale = 1.0

func _start_attack_release(clip_key: String, prev_state: String) -> void:
	var clip: Animation = _get_clip(clip_key)
	if clip == null:
		_exit_charge_hold()
		return
	var atk: AttackData = player.active_attack_data() if player != null else null
	var hold_frac: float = HOLD_FRACTIONS.get(clip_key, 0.35)
	var hold_time: float = clip.length * hold_frac
	var release_clip_length: float = clip.length - hold_time
	var release_mech_duration: float = _release_mech_duration(atk)
	var release_speed: float = release_clip_length / maxf(release_mech_duration, 0.01)

	var came_from_charge: bool = prev_state == "ChargeAttack" and _charge_clip_key == clip_key
	if came_from_charge:
		anim_player.speed_scale = 1.0
		anim_player.play(StringName("mix/" + clip_key), crossfade_seconds, release_speed)
		anim_player.seek(hold_time, true)
		_current_key = clip_key
	else:
		var total_mech: float = 0.0
		if atk != null:
			total_mech = atk.windup_time + release_mech_duration
		var full_speed: float = clip.length / maxf(total_mech, 0.01) if total_mech > 0.0 else 1.0
		_play_full(clip_key, full_speed, true)
	_holding_at_charge_point = false
	_charge_clip_key = ""

func _release_mech_duration(atk: AttackData) -> float:
	if atk == null:
		return 0.45
	return atk.active_time + atk.recovery_time * release_recovery_weight

func _get_clip(key: String) -> Animation:
	if anim_player == null:
		return null
	var full: StringName = StringName("mix/" + key)
	if not anim_player.has_animation(full):
		return null
	return anim_player.get_animation(full)

func _play_full(key: String, speed_scale: float, restart: bool = false) -> void:
	if anim_player == null:
		return
	var full: StringName = StringName("mix/" + key)
	if not anim_player.has_animation(full):
		return
	anim_player.speed_scale = 1.0
	if _current_key == key and not restart:
		anim_player.speed_scale = speed_scale
		return
	_current_key = key
	anim_player.play(full, crossfade_seconds, speed_scale)

func _play_key(key: String, speed_scale: float = 1.0, restart: bool = false) -> void:
	_play_full(key, speed_scale, restart)

func _find_animation_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c in n.get_children():
		var found: AnimationPlayer = _find_animation_player(c)
		if found != null:
			return found
	return null

func _find_node(n: Node, target_name: String) -> Node:
	if n.name == target_name:
		return n
	for c in n.get_children():
		var found: Node = _find_node(c, target_name)
		if found != null:
			return found
	return null
