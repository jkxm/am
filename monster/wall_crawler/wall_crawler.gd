class_name WallCrawler
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal phase_changed(phase: int)
signal part_broken(part_name: String)
signal state_changed(state: String)

@export_group("Health")
@export var max_health: float = 900.0
@export var phase_2_threshold: float = 0.6
@export var phase_3_threshold: float = 0.3

@export_group("Movement")
@export var ground_walk_speed: float = 3.0
@export var gravity: float = 22.0
@export var terminal_velocity: float = 30.0
@export var turn_speed: float = 8.0
@export var wall_crawl_speed: float = 5.0
@export var ground_to_wall_duration: float = 1.0
@export var wall_to_ground_duration: float = 0.5
@export var wall_to_wall_leap_duration: float = 0.5
@export var knockback_impulse: float = 4.0

@export_group("Breakable Parts")
@export var head_break_threshold: float = 150.0
@export var back_plate_break_threshold: float = 100.0
@export var rear_leg_break_threshold: float = 120.0
@export var back_plate_speed_penalty: float = 0.15
@export var rear_leg_charge_speed_penalty: float = 0.20
@export var head_broken_spit_accuracy_penalty: float = 15.0

@export_group("Weak Points")
@export var weak_point_damage_multiplier: float = 2.0
@export var state_weak_point_multiplier: float = 2.5
@export var belly_post_dive_duration: float = 1.0
@export var throat_weak_point_duration: float = 0.9

@export_group("Enrage / Exhaustion")
@export var enrage_damage_threshold: float = 150.0
@export var enrage_damage_window: float = 10.0
@export var enrage_duration: float = 30.0
@export var enrage_speed_multiplier: float = 1.3
@export var enrage_attack_speed_multiplier: float = 1.2
@export var exhaustion_duration: float = 15.0
@export var exhaustion_speed_multiplier: float = 0.6
@export var exhaustion_decision_interval_mult: float = 2.0
@export var exhaustion_belly_expose_duration: float = 2.0
@export var exhaustion_trigger_count: int = 4

@export_group("AI")
@export var wall_stay_duration: float = 8.0
@export var ground_stay_duration: float = 6.0
@export var decision_min: float = 0.5
@export var decision_max: float = 1.5

@export_group("References")
@export var player_path: NodePath
@export var wall_anchors_path: NodePath
@export var ground_anchors_path: NodePath
@export var acid_projectile_scene: PackedScene
@export var acid_puddle_scene: PackedScene

const NORMAL_COLOR: Color = Color(0.35, 0.35, 0.4, 1)
const WEAK_COLOR: Color = Color(0.95, 0.85, 0.25, 1)
const BREAKABLE_HEALTHY: Color = Color(0.3, 0.55, 0.85, 1)
const BREAKABLE_DAMAGED: Color = Color(0.9, 0.55, 0.2, 1)
const BREAKABLE_BROKEN: Color = Color(0.18, 0.15, 0.15, 1)
const ENRAGED_TINT: Color = Color(0.75, 0.2, 0.2, 1)
const EXHAUSTED_TINT: Color = Color(0.55, 0.65, 0.8, 1)
const LEG_COLOR: Color = Color(0.3, 0.3, 0.35, 1)
const TAIL_COLOR: Color = Color(0.3, 0.3, 0.35, 1)

var player: Node3D = null
var pending_attack: WCAttackData = null

var total_health: float = 0.0
var phase: int = 1

var head_hp: float = 0.0
var back_plate_left_hp: float = 0.0
var back_plate_right_hp: float = 0.0
var rear_leg_left_hp: float = 0.0
var rear_leg_right_hp: float = 0.0

var head_broken: bool = false
var back_plate_left_broken: bool = false
var back_plate_right_broken: bool = false
var rear_leg_left_broken: bool = false
var rear_leg_right_broken: bool = false

var is_enraged: bool = false
var is_exhausted: bool = false
var _enrage_timer: float = 0.0
var _exhaustion_timer: float = 0.0
var _recent_damage: float = 0.0
var _recent_damage_timer: float = 0.0

var is_on_wall_surface: bool = false
var current_wall_anchor: Marker3D = null
var _surface_stay_timer: float = 0.0
var _attack_count_since_rest: int = 0

var _cooldowns: Dictionary = {}
var _attacks: Array[WCAttackData] = []
var _spawn_transform: Transform3D

var _throat_weak_active: bool = false
var _state_weak_active: bool = false
var _state_weak_timer: float = 0.0
var _weak_focus: StringName = &"belly"

var _telegraph_active: bool = false
var _pending_transition: Dictionary = {}
var _post_attack_override_state: String = ""

@onready var _mesh_root: Node3D = $MeshRoot
@onready var _torso: CSGBox3D = $MeshRoot/Torso
@onready var _head: CSGBox3D = $MeshRoot/Head
@onready var _mandible_l: CSGBox3D = $MeshRoot/MandibleLeft
@onready var _mandible_r: CSGBox3D = $MeshRoot/MandibleRight
@onready var _back_plate_l: CSGBox3D = $MeshRoot/BackPlateLeft
@onready var _back_plate_r: CSGBox3D = $MeshRoot/BackPlateRight
@onready var _leg_fl: CSGBox3D = $MeshRoot/LegFrontLeft
@onready var _leg_fr: CSGBox3D = $MeshRoot/LegFrontRight
@onready var _leg_rl: CSGBox3D = $MeshRoot/LegRearLeft
@onready var _leg_rr: CSGBox3D = $MeshRoot/LegRearRight
@onready var _tail: CSGBox3D = $MeshRoot/Tail
@onready var _belly_marker: CSGBox3D = $MeshRoot/BellyWeakPoint
@onready var _back_marker: CSGBox3D = $MeshRoot/BackWeakPoint
@onready var _throat_marker: CSGBox3D = $MeshRoot/ThroatWeakPoint
@onready var _attack_hitbox: Hitbox = $AttackHitbox
@onready var _attack_hitbox_shape: CollisionShape3D = $AttackHitbox/CollisionShape3D
@onready var _projectile_spawn: Marker3D = $MeshRoot/ProjectileSpawn
@onready var _state_machine: WCStateMachine = $StateMachine

@onready var _hurtbox_map: Dictionary = {
	"torso": $Hurtboxes/TorsoHurtbox,
	"head": $Hurtboxes/HeadHurtbox,
	"back_plate_left": $Hurtboxes/BackPlateLeftHurtbox,
	"back_plate_right": $Hurtboxes/BackPlateRightHurtbox,
	"rear_leg_left": $Hurtboxes/RearLegLeftHurtbox,
	"rear_leg_right": $Hurtboxes/RearLegRightHurtbox,
	"belly": $Hurtboxes/BellyHurtbox,
	"back": $Hurtboxes/BackHurtbox,
	"throat": $Hurtboxes/ThroatHurtbox,
}

var _torso_mat: StandardMaterial3D
var _head_mat: StandardMaterial3D
var _mandible_l_mat: StandardMaterial3D
var _mandible_r_mat: StandardMaterial3D
var _back_plate_l_mat: StandardMaterial3D
var _back_plate_r_mat: StandardMaterial3D
var _leg_rl_mat: StandardMaterial3D
var _leg_rr_mat: StandardMaterial3D
var _belly_mat: StandardMaterial3D
var _back_mat: StandardMaterial3D
var _throat_mat: StandardMaterial3D

var _wall_anchors: Array[Marker3D] = []
var _ground_anchors: Array[Marker3D] = []

func _ready() -> void:
	add_to_group(&"monsters")
	_spawn_transform = global_transform
	total_health = max_health
	head_hp = head_break_threshold
	back_plate_left_hp = back_plate_break_threshold
	back_plate_right_hp = back_plate_break_threshold
	rear_leg_left_hp = rear_leg_break_threshold
	rear_leg_right_hp = rear_leg_break_threshold

	if player_path != NodePath():
		player = get_node_or_null(player_path)

	_collect_anchors()
	_cache_materials()
	_build_attacks()

	_attack_hitbox.source = self
	_attack_hitbox.deactivate()

	for key in _hurtbox_map.keys():
		var hb: Hurtbox = _hurtbox_map[key]
		hb.owner_ref = self
		hb.hit_received.connect(_on_hurtbox_hit.bind(String(key)))

	_state_machine.setup(self)
	_state_machine.state_changed.connect(_on_state_changed)
	_refresh_colors()
	health_changed.emit(total_health, max_health)
	phase_changed.emit(phase)

func _physics_process(delta: float) -> void:
	for key: String in _cooldowns.keys():
		_cooldowns[key] = maxf(0.0, _cooldowns[key] - delta)

	_update_enrage_exhaustion(delta)
	_update_surface_stay(delta)
	_update_state_weak_point(delta)

	_state_machine.physics_step(delta)

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = -1.0
		return
	velocity.y = maxf(velocity.y - gravity * delta, -terminal_velocity)

func face_toward(direction: Vector3, weight: float) -> void:
	if direction.length() < 0.01:
		return
	var flat: Vector3 = direction
	flat.y = 0.0
	if flat.length() < 0.01:
		return
	var target_yaw: float = atan2(flat.x, flat.z)
	_mesh_root.rotation.y = lerp_angle(_mesh_root.rotation.y, target_yaw, clampf(turn_speed * weight, 0.0, 1.0))

func decision_interval_mult() -> float:
	if is_exhausted:
		return exhaustion_decision_interval_mult
	if is_enraged:
		return 0.6
	return 1.0

func default_combat_state() -> String:
	return "CombatWall" if is_on_wall_surface else "CombatGround"

func pick_attack(distance: float, preferred_surface: int) -> WCAttackData:
	var candidates: Array[WCAttackData] = []
	for data: WCAttackData in _attacks:
		if data.requires_head and head_broken:
			continue
		if data.requires_rear_legs and rear_leg_left_broken and rear_leg_right_broken:
			continue
		if data.surface != WCAttackData.Surface.EITHER and data.surface != preferred_surface:
			continue
		if distance < data.min_range or distance > data.max_range:
			continue
		var remaining: float = _cooldowns.get(data.label, 0.0)
		if remaining > 0.0:
			continue
		if data.kind == WCAttackData.Kind.BARRAGE and not is_enraged:
			continue
		candidates.append(data)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]

func should_rest() -> bool:
	_attack_count_since_rest += 1
	if _attack_count_since_rest >= exhaustion_trigger_count:
		_attack_count_since_rest = 0
		_start_exhaustion()
		return true
	return false

func should_transition_to_wall() -> bool:
	if _wall_anchors.is_empty():
		return false
	if is_on_wall_surface:
		return false
	var wall_bias: float = _phase_wall_weight()
	if _surface_stay_timer < ground_stay_duration:
		return false
	return randf() < wall_bias

func should_transition_to_ground() -> bool:
	if not is_on_wall_surface:
		return false
	var ground_bias: float = _phase_ground_weight()
	if _surface_stay_timer < wall_stay_duration:
		return false
	return randf() < ground_bias

func begin_transition() -> Dictionary:
	_pending_transition.clear()
	var info: Dictionary = {}
	if is_on_wall_surface:
		var target: Marker3D = _pick_ground_anchor()
		if target != null:
			info["target_pos"] = target.global_position
			info["target_basis"] = target.global_transform.basis
		else:
			info["target_pos"] = _spawn_transform.origin
			info["target_basis"] = Basis.IDENTITY
		info["duration"] = wall_to_ground_duration
		info["next_state"] = "CombatGround"
		_pending_transition["to_wall"] = false
	else:
		var anchor: Marker3D = _pick_wall_anchor()
		if anchor != null:
			info["target_pos"] = anchor.global_position
			info["target_basis"] = anchor.global_transform.basis
			_pending_transition["anchor"] = anchor
			info["duration"] = ground_to_wall_duration if not is_on_wall_surface else wall_to_wall_leap_duration
			info["next_state"] = "CombatWall"
			_pending_transition["to_wall"] = true
		else:
			info["target_pos"] = global_position
			info["target_basis"] = global_transform.basis
			info["duration"] = 0.1
			info["next_state"] = "CombatGround"
	return info

func finish_transition() -> void:
	if _pending_transition.get("to_wall", false):
		is_on_wall_surface = true
		current_wall_anchor = _pending_transition.get("anchor", null)
	else:
		is_on_wall_surface = false
		current_wall_anchor = null
	_surface_stay_timer = 0.0
	velocity = Vector3.ZERO

func pick_new_wall_anchor() -> void:
	var anchor: Marker3D = _pick_wall_anchor(current_wall_anchor)
	if anchor != null:
		_pending_transition.clear()
		_pending_transition["to_wall"] = true
		_pending_transition["anchor"] = anchor

func update_wall_cling(_delta: float) -> void:
	if current_wall_anchor == null:
		return
	global_position = current_wall_anchor.global_position
	_mesh_root.global_transform.basis = current_wall_anchor.global_transform.basis
	if player != null:
		var to_player: Vector3 = player.global_position - global_position
		var basis: Basis = current_wall_anchor.global_transform.basis
		var forward: Vector3 = -basis.z
		if forward.dot(to_player) < 0.0:
			pass

func slide_along_wall(dir: Vector3, speed: float, delta: float) -> void:
	var basis: Basis = global_transform.basis
	var tangent: Vector3 = dir - basis.y * dir.dot(basis.y)
	if tangent.length() < 0.01:
		return
	tangent = tangent.normalized()
	global_position += tangent * speed * delta

func clear_wall_cling() -> void:
	is_on_wall_surface = false
	current_wall_anchor = null
	var basis: Basis = Basis.IDENTITY
	global_transform = Transform3D(basis, global_position)

func begin_attack_telegraph(data: WCAttackData) -> void:
	_telegraph_active = true
	_torso_mat.albedo_color = data.telegraph_color
	_torso_mat.emission_enabled = true
	_torso_mat.emission = data.telegraph_color
	_torso_mat.emission_energy_multiplier = 0.6
	_mesh_root.scale = Vector3.ONE * 1.05
	_apply_telegraph_pose(data)

func end_attack_telegraph() -> void:
	_telegraph_active = false
	_mesh_root.scale = Vector3.ONE
	_refresh_colors()

func _apply_telegraph_pose(data: WCAttackData) -> void:
	match data.kind:
		WCAttackData.Kind.PROJECTILE, WCAttackData.Kind.BARRAGE:
			_torso.position = Vector3(0, 1.3, 0)
		WCAttackData.Kind.DIVE:
			_torso.position = Vector3(0, 0.9, -0.2)
		_:
			_torso.position = Vector3(0, 1.1, 0)

func activate_attack_hitbox(data: WCAttackData) -> void:
	var speed_mult: float = 1.0
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = data.hitbox_size
	_attack_hitbox_shape.shape = shape
	_attack_hitbox_shape.position = data.hitbox_offset
	var damage_mult: float = 1.0
	if data.kind == WCAttackData.Kind.CHARGE:
		if rear_leg_left_broken:
			speed_mult -= rear_leg_charge_speed_penalty
		if rear_leg_right_broken:
			speed_mult -= rear_leg_charge_speed_penalty
	_attack_hitbox.damage = data.damage * damage_mult
	_attack_hitbox.hitstop_ms = data.hitstop_ms
	_attack_hitbox.screen_shake_amplitude = data.screen_shake_amplitude
	_attack_hitbox.stagger = true
	_attack_hitbox.activate()

func deactivate_attack_hitbox() -> void:
	_attack_hitbox.deactivate()

func start_cooldown(label: String, seconds: float) -> void:
	var mult: float = 1.0
	if phase == 3:
		mult *= 0.6
	if is_enraged:
		mult *= 0.8
	_cooldowns[label] = seconds * mult

func set_throat_weak_point(active: bool) -> void:
	_throat_weak_active = active
	if _throat_marker != null:
		_throat_marker.visible = active
	_refresh_colors()

func open_state_weak_point(duration: float) -> void:
	_state_weak_active = true
	_state_weak_timer = duration + (exhaustion_belly_expose_duration if is_exhausted else 0.0)
	_refresh_colors()

func close_state_weak_point() -> void:
	_state_weak_active = false
	_state_weak_timer = 0.0
	_refresh_colors()

func _update_state_weak_point(delta: float) -> void:
	if _state_weak_active:
		_state_weak_timer -= delta
		if _state_weak_timer <= 0.0:
			_state_weak_active = false
			_refresh_colors()

func spawn_acid_spit(data: WCAttackData, offset_deg: float) -> void:
	if acid_projectile_scene == null or acid_puddle_scene == null:
		return
	if player == null:
		return
	var from: Vector3 = _projectile_spawn.global_position
	var to: Vector3 = player.global_position + Vector3(0, 0.9, 0)
	var dir: Vector3 = (to - from).normalized()

	var total_offset_deg: float = offset_deg
	if head_broken:
		total_offset_deg += randf_range(-head_broken_spit_accuracy_penalty, head_broken_spit_accuracy_penalty)
	if total_offset_deg != 0.0:
		dir = dir.rotated(Vector3.UP, deg_to_rad(total_offset_deg))

	var projectile: AcidProjectile = acid_projectile_scene.instantiate()
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	scene_root.add_child(projectile)
	projectile.global_position = from
	projectile.puddle_scene = acid_puddle_scene
	projectile.damage = data.projectile_damage
	projectile.speed = data.projectile_speed
	projectile.puddle_duration = data.projectile_puddle_duration
	projectile.puddle_radius = data.projectile_puddle_radius
	projectile.launch(dir, data.projectile_speed, self)

func apply_dive_shockwave(radius: float, damage: float) -> void:
	if player == null:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if dist <= radius and player.has_method("take_environmental_damage"):
		player.take_environmental_damage(damage)

func on_died() -> void:
	pass

func respawn() -> void:
	global_transform = _spawn_transform
	total_health = max_health
	head_hp = head_break_threshold
	back_plate_left_hp = back_plate_break_threshold
	back_plate_right_hp = back_plate_break_threshold
	rear_leg_left_hp = rear_leg_break_threshold
	rear_leg_right_hp = rear_leg_break_threshold
	head_broken = false
	back_plate_left_broken = false
	back_plate_right_broken = false
	rear_leg_left_broken = false
	rear_leg_right_broken = false
	is_enraged = false
	is_exhausted = false
	_enrage_timer = 0.0
	_exhaustion_timer = 0.0
	_recent_damage = 0.0
	is_on_wall_surface = false
	current_wall_anchor = null
	phase = 1
	_cooldowns.clear()
	_attack_count_since_rest = 0
	velocity = Vector3.ZERO
	_refresh_colors()
	health_changed.emit(total_health, max_health)
	phase_changed.emit(phase)

func current_state_name() -> String:
	return _state_machine.current_name()

func _phase_wall_weight() -> float:
	match phase:
		1: return 0.3
		2: return 0.7
		3: return 0.5
	return 0.3

func _phase_ground_weight() -> float:
	match phase:
		1: return 0.7
		2: return 0.3
		3: return 0.5
	return 0.7

func _phase_weak_focus() -> StringName:
	match phase:
		1: return &"belly"
		2: return &"back"
		3: return &"head"
	return &"belly"

func _collect_anchors() -> void:
	_wall_anchors.clear()
	_ground_anchors.clear()
	if wall_anchors_path != NodePath():
		var wall_root: Node = get_node_or_null(wall_anchors_path)
		if wall_root != null:
			for child in wall_root.get_children():
				if child is Marker3D:
					_wall_anchors.append(child as Marker3D)
	if ground_anchors_path != NodePath():
		var ground_root: Node = get_node_or_null(ground_anchors_path)
		if ground_root != null:
			for child in ground_root.get_children():
				if child is Marker3D:
					_ground_anchors.append(child as Marker3D)

func _pick_wall_anchor(exclude: Marker3D = null) -> Marker3D:
	var candidates: Array[Marker3D] = []
	for a: Marker3D in _wall_anchors:
		if a != exclude:
			candidates.append(a)
	if candidates.is_empty():
		return null
	if player == null:
		return candidates[randi() % candidates.size()]
	candidates.sort_custom(func(x: Marker3D, y: Marker3D) -> bool:
		return x.global_position.distance_to(player.global_position) < y.global_position.distance_to(player.global_position))
	var pool_size: int = mini(3, candidates.size())
	return candidates[randi() % pool_size]

func _pick_ground_anchor() -> Marker3D:
	if _ground_anchors.is_empty():
		return null
	if player == null:
		return _ground_anchors[randi() % _ground_anchors.size()]
	var best: Marker3D = null
	var best_dist: float = INF
	for a: Marker3D in _ground_anchors:
		var d: float = a.global_position.distance_to(player.global_position)
		if d < best_dist:
			best_dist = d
			best = a
	return best

func _update_surface_stay(delta: float) -> void:
	_surface_stay_timer += delta

func _update_enrage_exhaustion(delta: float) -> void:
	if _recent_damage_timer > 0.0:
		_recent_damage_timer -= delta
		if _recent_damage_timer <= 0.0:
			_recent_damage = 0.0

	if is_enraged:
		_enrage_timer -= delta
		if _enrage_timer <= 0.0:
			is_enraged = false
			_start_exhaustion()
			_refresh_colors()

	if is_exhausted:
		_exhaustion_timer -= delta
		if _exhaustion_timer <= 0.0:
			is_exhausted = false
			_refresh_colors()

func _start_enrage() -> void:
	if is_enraged:
		return
	is_enraged = true
	_enrage_timer = enrage_duration
	is_exhausted = false
	_recent_damage = 0.0
	_refresh_colors()
	_burst_barrage_on_enrage()

func _start_exhaustion() -> void:
	is_exhausted = true
	_exhaustion_timer = exhaustion_duration
	_refresh_colors()

func _burst_barrage_on_enrage() -> void:
	if acid_projectile_scene == null or acid_puddle_scene == null:
		return
	for i in range(6):
		var angle: float = float(i) * TAU / 6.0
		var dir: Vector3 = Vector3(cos(angle), 0.15, sin(angle))
		var projectile: AcidProjectile = acid_projectile_scene.instantiate()
		var scene_root: Node = get_tree().current_scene
		if scene_root == null:
			scene_root = get_parent()
		scene_root.add_child(projectile)
		projectile.global_position = _projectile_spawn.global_position
		projectile.puddle_scene = acid_puddle_scene
		projectile.damage = 30.0
		projectile.puddle_duration = 6.0
		projectile.puddle_radius = 1.8
		projectile.launch(dir, 10.0, self)

func _on_hurtbox_hit(event: DamageEvent, part_name: String) -> void:
	var base_amount: float = event.amount
	var amount: float = base_amount
	var is_weak: bool = _is_weak_hit(part_name)
	if is_weak:
		amount *= _active_weak_multiplier()

	total_health = maxf(0.0, total_health - amount)
	_recent_damage += amount
	_recent_damage_timer = enrage_damage_window

	var push: Vector3 = Vector3(event.direction.x, 0.0, event.direction.z)
	if push.length() > 0.01 and not is_on_wall_surface:
		push = push.normalized() * knockback_impulse
		velocity.x += push.x
		velocity.z += push.z

	_apply_breakable_damage(part_name, amount)

	_maybe_phase_shift()
	if not is_enraged and _recent_damage >= enrage_damage_threshold:
		_start_enrage()

	_refresh_colors()
	health_changed.emit(total_health, max_health)

	if total_health <= 0.0 and current_state_name() != "Dying":
		_state_machine.change_to("Dying")

func _active_weak_multiplier() -> float:
	if _state_weak_active or _throat_weak_active:
		return state_weak_point_multiplier
	return weak_point_damage_multiplier

func _is_weak_hit(part: String) -> bool:
	if part == "throat" and _throat_weak_active:
		return true
	if _state_weak_active:
		if part == "belly" or part == "back":
			return true
	var focus: StringName = _phase_weak_focus()
	if part == String(focus):
		return true
	return false

func _apply_breakable_damage(part_name: String, amount: float) -> void:
	match part_name:
		"head":
			if not head_broken:
				head_hp = maxf(0.0, head_hp - amount)
				if head_hp <= 0.0:
					head_broken = true
					part_broken.emit("head")
		"back_plate_left":
			if not back_plate_left_broken:
				back_plate_left_hp = maxf(0.0, back_plate_left_hp - amount)
				if back_plate_left_hp <= 0.0:
					back_plate_left_broken = true
					part_broken.emit("back_plate_left")
					_drop_fallen_plate(_back_plate_l.global_position)
		"back_plate_right":
			if not back_plate_right_broken:
				back_plate_right_hp = maxf(0.0, back_plate_right_hp - amount)
				if back_plate_right_hp <= 0.0:
					back_plate_right_broken = true
					part_broken.emit("back_plate_right")
					_drop_fallen_plate(_back_plate_r.global_position)
		"rear_leg_left":
			if not rear_leg_left_broken:
				rear_leg_left_hp = maxf(0.0, rear_leg_left_hp - amount)
				if rear_leg_left_hp <= 0.0:
					rear_leg_left_broken = true
					part_broken.emit("rear_leg_left")
		"rear_leg_right":
			if not rear_leg_right_broken:
				rear_leg_right_hp = maxf(0.0, rear_leg_right_hp - amount)
				if rear_leg_right_hp <= 0.0:
					rear_leg_right_broken = true
					part_broken.emit("rear_leg_right")

func _drop_fallen_plate(from: Vector3) -> void:
	pass

func _maybe_phase_shift() -> void:
	var ratio: float = total_health / maxf(max_health, 0.001)
	var new_phase: int = phase
	if ratio <= phase_3_threshold and phase < 3:
		new_phase = 3
	elif ratio <= phase_2_threshold and phase < 2:
		new_phase = 2
	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)

func _on_state_changed(state_name: String) -> void:
	state_changed.emit(state_name)

func _cache_materials() -> void:
	_torso_mat = _make_mat(_torso, NORMAL_COLOR)
	_head_mat = _make_mat(_head, NORMAL_COLOR)
	_mandible_l_mat = _make_mat(_mandible_l, BREAKABLE_HEALTHY)
	_mandible_r_mat = _make_mat(_mandible_r, BREAKABLE_HEALTHY)
	_back_plate_l_mat = _make_mat(_back_plate_l, BREAKABLE_HEALTHY)
	_back_plate_r_mat = _make_mat(_back_plate_r, BREAKABLE_HEALTHY)
	_leg_rl_mat = _make_mat(_leg_rl, BREAKABLE_HEALTHY)
	_leg_rr_mat = _make_mat(_leg_rr, BREAKABLE_HEALTHY)
	_make_mat(_leg_fl, LEG_COLOR)
	_make_mat(_leg_fr, LEG_COLOR)
	_make_mat(_tail, TAIL_COLOR)
	_belly_mat = _make_mat(_belly_marker, WEAK_COLOR)
	_back_mat = _make_mat(_back_marker, WEAK_COLOR)
	_throat_mat = _make_mat(_throat_marker, WEAK_COLOR)
	_throat_marker.visible = false

func _make_mat(node: CSGBox3D, color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	node.material = m
	return m

func _refresh_colors() -> void:
	if _telegraph_active:
		return

	var tint: Color = NORMAL_COLOR
	if is_enraged:
		tint = ENRAGED_TINT
	elif is_exhausted:
		tint = EXHAUSTED_TINT

	_torso_mat.albedo_color = tint
	_torso_mat.emission_enabled = is_enraged
	if is_enraged:
		_torso_mat.emission = tint
		_torso_mat.emission_energy_multiplier = 0.35

	_head_mat.albedo_color = tint
	_apply_breakable_color(_mandible_l_mat, head_hp, head_break_threshold, head_broken)
	_apply_breakable_color(_mandible_r_mat, head_hp, head_break_threshold, head_broken)
	_apply_breakable_color(_back_plate_l_mat, back_plate_left_hp, back_plate_break_threshold, back_plate_left_broken)
	_apply_breakable_color(_back_plate_r_mat, back_plate_right_hp, back_plate_break_threshold, back_plate_right_broken)
	_apply_breakable_color(_leg_rl_mat, rear_leg_left_hp, rear_leg_break_threshold, rear_leg_left_broken)
	_apply_breakable_color(_leg_rr_mat, rear_leg_right_hp, rear_leg_break_threshold, rear_leg_right_broken)

	_weak_focus = _phase_weak_focus()
	var belly_active: bool = _weak_focus == &"belly" or (_state_weak_active and _phase_weak_focus() != &"back")
	var back_active: bool = _weak_focus == &"back" or (_state_weak_active and _phase_weak_focus() == &"back")
	_belly_marker.visible = belly_active
	_back_marker.visible = back_active
	_belly_mat.emission_enabled = belly_active
	_back_mat.emission_enabled = back_active
	if belly_active:
		_belly_mat.emission = WEAK_COLOR
		_belly_mat.emission_energy_multiplier = 0.5
	if back_active:
		_back_mat.emission = WEAK_COLOR
		_back_mat.emission_energy_multiplier = 0.5

	if _throat_weak_active:
		_throat_mat.emission_enabled = true
		_throat_mat.emission = WEAK_COLOR
		_throat_mat.emission_energy_multiplier = 0.8
	else:
		_throat_mat.emission_enabled = false

func _apply_breakable_color(mat: StandardMaterial3D, hp: float, max_hp: float, broken: bool) -> void:
	if broken:
		mat.albedo_color = BREAKABLE_BROKEN
		mat.emission_enabled = false
		return
	var ratio: float = hp / maxf(max_hp, 0.001)
	if ratio > 0.6:
		mat.albedo_color = BREAKABLE_HEALTHY
	else:
		mat.albedo_color = BREAKABLE_DAMAGED

func wall_move_speed() -> float:
	var speed: float = wall_crawl_speed
	if back_plate_left_broken:
		speed *= (1.0 - back_plate_speed_penalty)
	if back_plate_right_broken:
		speed *= (1.0 - back_plate_speed_penalty)
	if is_enraged:
		speed *= enrage_speed_multiplier
	elif is_exhausted:
		speed *= exhaustion_speed_multiplier
	return speed

func _build_attacks() -> void:
	_attacks.clear()

	var swipe := WCAttackData.new()
	swipe.label = "LegSwipe"
	swipe.kind = WCAttackData.Kind.MELEE
	swipe.surface = WCAttackData.Surface.GROUND
	swipe.telegraph_time = 0.3
	swipe.active_time = 0.15
	swipe.recovery_time = 0.4
	swipe.damage = 20.0
	swipe.min_range = 0.0
	swipe.max_range = 3.5
	swipe.cooldown = 2.0
	swipe.advance_distance = 0.6
	swipe.hitbox_offset = Vector3(0, 0.8, -2.2)
	swipe.hitbox_size = Vector3(3.0, 1.0, 3.0)
	swipe.telegraph_color = Color(1, 0.55, 0.25, 1)
	_attacks.append(swipe)

	var bite := WCAttackData.new()
	bite.label = "LungeBite"
	bite.kind = WCAttackData.Kind.MELEE
	bite.surface = WCAttackData.Surface.GROUND
	bite.telegraph_time = 0.5
	bite.active_time = 0.2
	bite.recovery_time = 0.6
	bite.damage = 45.0
	bite.min_range = 2.0
	bite.max_range = 6.5
	bite.cooldown = 4.0
	bite.advance_distance = 4.0
	bite.hitbox_offset = Vector3(0, 1.2, -2.8)
	bite.hitbox_size = Vector3(1.6, 1.5, 3.0)
	bite.telegraph_color = Color(1, 0.3, 0.15, 1)
	bite.requires_head = true
	_attacks.append(bite)

	var tsweep := WCAttackData.new()
	tsweep.label = "TailSweep"
	tsweep.kind = WCAttackData.Kind.MELEE
	tsweep.surface = WCAttackData.Surface.GROUND
	tsweep.telegraph_time = 0.4
	tsweep.active_time = 0.25
	tsweep.recovery_time = 0.5
	tsweep.damage = 30.0
	tsweep.min_range = 0.0
	tsweep.max_range = 4.2
	tsweep.cooldown = 3.0
	tsweep.hitbox_offset = Vector3(0, 0.7, 2.2)
	tsweep.hitbox_size = Vector3(4.0, 1.2, 3.5)
	tsweep.telegraph_color = Color(1, 0.65, 0.3, 1)
	_attacks.append(tsweep)

	var gspit := WCAttackData.new()
	gspit.label = "GroundSpit"
	gspit.kind = WCAttackData.Kind.PROJECTILE
	gspit.surface = WCAttackData.Surface.GROUND
	gspit.telegraph_time = 0.8
	gspit.active_time = 0.1
	gspit.recovery_time = 0.6
	gspit.damage = 0.0
	gspit.projectile_damage = 35.0
	gspit.projectile_speed = 12.0
	gspit.projectile_puddle_duration = 8.0
	gspit.projectile_puddle_radius = 2.0
	gspit.projectile_spawn_offset = Vector3(0, 1.4, -1.4)
	gspit.min_range = 4.0
	gspit.max_range = 22.0
	gspit.cooldown = 5.0
	gspit.telegraph_color = Color(0.6, 1.0, 0.3, 1)
	gspit.exposes_throat = true
	gspit.requires_head = true
	_attacks.append(gspit)

	var wclaw := WCAttackData.new()
	wclaw.label = "WallClaw"
	wclaw.kind = WCAttackData.Kind.MELEE
	wclaw.surface = WCAttackData.Surface.WALL
	wclaw.telegraph_time = 0.25
	wclaw.active_time = 0.15
	wclaw.recovery_time = 0.3
	wclaw.damage = 25.0
	wclaw.min_range = 0.0
	wclaw.max_range = 4.0
	wclaw.cooldown = 1.5
	wclaw.hitbox_offset = Vector3(0, 0.0, -2.0)
	wclaw.hitbox_size = Vector3(3.5, 3.0, 3.0)
	wclaw.telegraph_color = Color(1, 0.55, 0.25, 1)
	_attacks.append(wclaw)

	var wcharge := WCAttackData.new()
	wcharge.label = "WallCharge"
	wcharge.kind = WCAttackData.Kind.CHARGE
	wcharge.surface = WCAttackData.Surface.WALL
	wcharge.telegraph_time = 0.5
	wcharge.active_time = 0.6
	wcharge.recovery_time = 0.5
	wcharge.damage = 50.0
	wcharge.advance_speed = 14.0
	wcharge.min_range = 0.0
	wcharge.max_range = 14.0
	wcharge.cooldown = 6.0
	wcharge.hitbox_offset = Vector3(0, 0.0, -1.5)
	wcharge.hitbox_size = Vector3(2.6, 2.2, 3.0)
	wcharge.telegraph_color = Color(1, 0.4, 0.15, 1)
	wcharge.requires_rear_legs = true
	_attacks.append(wcharge)

	var wspit := WCAttackData.new()
	wspit.label = "WallSpit"
	wspit.kind = WCAttackData.Kind.PROJECTILE
	wspit.surface = WCAttackData.Surface.WALL
	wspit.telegraph_time = 0.6
	wspit.active_time = 0.1
	wspit.recovery_time = 0.4
	wspit.damage = 0.0
	wspit.projectile_damage = 40.0
	wspit.projectile_speed = 15.0
	wspit.projectile_puddle_duration = 8.0
	wspit.projectile_puddle_radius = 2.0
	wspit.min_range = 0.0
	wspit.max_range = 30.0
	wspit.cooldown = 4.0
	wspit.telegraph_color = Color(0.6, 1.0, 0.3, 1)
	wspit.exposes_throat = true
	wspit.requires_head = true
	_attacks.append(wspit)

	var dive := WCAttackData.new()
	dive.label = "Dive"
	dive.kind = WCAttackData.Kind.DIVE
	dive.surface = WCAttackData.Surface.WALL
	dive.telegraph_time = 0.7
	dive.active_time = 0.4
	dive.recovery_time = 0.9
	dive.damage = 60.0
	dive.dive_speed = 18.0
	dive.dive_shockwave_radius = 3.0
	dive.dive_shockwave_damage = 20.0
	dive.min_range = 0.0
	dive.max_range = 25.0
	dive.cooldown = 8.0
	dive.telegraph_color = Color(1, 0.2, 0.2, 1)
	dive.exposes_belly_on_recovery = true
	_attacks.append(dive)

	var barrage := WCAttackData.new()
	barrage.label = "Barrage"
	barrage.kind = WCAttackData.Kind.BARRAGE
	barrage.surface = WCAttackData.Surface.WALL
	barrage.telegraph_time = 0.6
	barrage.active_time = 1.0
	barrage.recovery_time = 0.5
	barrage.damage = 0.0
	barrage.projectile_damage = 25.0
	barrage.projectile_speed = 14.0
	barrage.projectile_puddle_duration = 6.0
	barrage.projectile_puddle_radius = 1.6
	barrage.barrage_count = 3
	barrage.barrage_delay = 0.3
	barrage.barrage_spread_deg = 30.0
	barrage.min_range = 0.0
	barrage.max_range = 30.0
	barrage.cooldown = 10.0
	barrage.telegraph_color = Color(0.6, 1.0, 0.3, 1)
	barrage.requires_head = true
	_attacks.append(barrage)
