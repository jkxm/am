class_name YBotAnimator
extends Node3D

const BOT_SCENE_PATH: String = "res://assets/Y Bot.fbx"

const ANIM_SOURCES: Dictionary = {
	"idle": "res://assets/Warrior Idle.fbx",
	"run": "res://assets/Running.fbx",
	"wall_run": "res://assets/Wall Run.fbx",
	"gs_attack": "res://assets/great sword slash.fbx",
	"gs_cast": "res://assets/great sword casting.fbx",
	"gs_slide_attack": "res://assets/Great Sword Slide Attack.fbx",
	"dodge_roll": "res://assets/Sprinting Forward Roll.fbx",
}

# Fraction of each attack clip that is "windup" — the point where the pose
# freezes while charging and resumes from on release.
const HOLD_FRACTIONS: Dictionary = {
	"gs_attack": 0.35,
	"gs_cast": 0.40,
	"gs_slide_attack": 0.30,
}

@export var model_scale: float = 1.0
@export var model_y_offset: float = 0.0
@export var model_yaw_deg: float = 180.0
@export var crossfade_seconds: float = 0.08

@export var charge_buildup_seconds: float = 0.45
@export var release_recovery_weight: float = 0.6

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
				if key in ["idle", "run", "wall_run"]:
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

func _process(_delta: float) -> void:
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

func _on_state_changed(state: String) -> void:
	var prev_state: String = _current_state
	_current_state = state
	if prev_state == "ChargeAttack" and state != "ChargeAttack":
		pass
	match state:
		"Idle":
			_exit_charge_hold()
			_play_key("idle")
		"WalkRun":
			_exit_charge_hold()
			_play_key("run")
		"JumpFall":
			_exit_charge_hold()
			_play_key("idle")
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
			_play_key("idle")
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
			_start_attack_release("gs_cast", prev_state)
		"Stagger":
			_exit_charge_hold()
			_play_key("idle")
		_:
			_exit_charge_hold()
			_play_key("idle")

func _charge_clip_for_context() -> String:
	if player == null:
		return "gs_attack"
	if not player.is_on_floor():
		return "gs_cast"
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
