class_name MonsterBrawler
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal phase_changed(phase: int)
signal part_broken(part_name: String)
signal state_changed(state: String)

@export var max_health: float = 500.0
@export var chase_speed: float = 3.5
@export var gravity: float = 22.0
@export var terminal_velocity: float = 30.0
@export var turn_speed: float = 8.0
@export var exhaustion_trigger_count: int = 3
@export var phase2_threshold: float = 0.5
@export var knockback_impulse: float = 6.0
@export var player_path: NodePath

@onready var _mesh_root: Node3D = $MeshRoot
@onready var _torso: MeshInstance3D = $MeshRoot/Torso
@onready var _head: MeshInstance3D = $MeshRoot/Head
@onready var _tail: MeshInstance3D = $MeshRoot/Tail
@onready var _attack_hitbox: Hitbox = $MeshRoot/AttackHitbox
@onready var _attack_hitbox_shape: CollisionShape3D = $MeshRoot/AttackHitbox/CollisionShape3D
@onready var _state_machine: MonsterStateMachine = $StateMachine
@onready var _part_hurtboxes: Array = [
	$MeshRoot/Hurtboxes/TorsoHurtbox,
	$MeshRoot/Hurtboxes/HeadHurtbox,
	$MeshRoot/Hurtboxes/TailHurtbox,
]
@onready var _torso_material: StandardMaterial3D = _mat_for(_torso)
@onready var _head_material: StandardMaterial3D = _mat_for(_head)
@onready var _tail_material: StandardMaterial3D = _mat_for(_tail)

const NORMAL_COLOR: Color = Color(0.35, 0.55, 0.35, 1)
const WEAK_COLOR: Color = Color(0.95, 0.85, 0.25, 1)
const BROKEN_COLOR: Color = Color(0.25, 0.25, 0.3, 1)
const TELEGRAPH_COLOR_DEFAULT: Color = Color(0.95, 0.35, 0.2, 1)
const ENRAGED_COLOR: Color = Color(0.7, 0.15, 0.15, 1)
const HEAD_HP: float = 110.0
const TAIL_HP: float = 90.0

var player: Node3D = null
var pending_attack: MonsterAttackData = null
var total_health: float = 0.0
var phase: int = 1
var head_hp: float = HEAD_HP
var tail_hp: float = TAIL_HP
var head_broken: bool = false
var tail_broken: bool = false
var _spawn_transform: Transform3D
var _cooldowns: Dictionary = {}
var _attacks: Array[MonsterAttackData] = []
var _since_exhaustion_reset: int = 0
var _telegraph_active: bool = false

func _ready() -> void:
	add_to_group(&"monsters")
	_spawn_transform = global_transform
	total_health = max_health
	_attacks = _build_attacks()
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	_attack_hitbox.source = self
	_attack_hitbox.deactivate()
	for hb: Hurtbox in _part_hurtboxes:
		hb.owner_ref = self
		hb.hit_received.connect(_on_hurtbox_hit.bind(hb))
	_state_machine.setup(self)
	_state_machine.state_changed.connect(_on_state_changed)
	_refresh_colors()
	health_changed.emit(total_health, max_health)
	phase_changed.emit(phase)

func _physics_process(delta: float) -> void:
	for key: String in _cooldowns.keys():
		_cooldowns[key] = maxf(0.0, _cooldowns[key] - delta)
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
	var target_yaw: float = atan2(direction.x, direction.z)
	_mesh_root.rotation.y = lerp_angle(_mesh_root.rotation.y, target_yaw, clampf(turn_speed * weight, 0.0, 1.0))

func pick_attack(distance: float) -> MonsterAttackData:
	var candidates: Array[MonsterAttackData] = []
	for data: MonsterAttackData in _attacks:
		if data.requires_head and head_broken:
			continue
		if data.requires_tail and tail_broken:
			continue
		if distance < data.min_range or distance > data.max_range:
			continue
		var remaining: float = _cooldowns.get(data.label, 0.0)
		if remaining > 0.0:
			continue
		candidates.append(data)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]

func begin_attack_telegraph(data: MonsterAttackData) -> void:
	_telegraph_active = true
	_torso_material.albedo_color = data.telegraph_color
	_torso_material.emission_enabled = true
	_torso_material.emission = data.telegraph_color
	_torso_material.emission_energy_multiplier = 0.6

func end_attack_telegraph() -> void:
	_telegraph_active = false
	_refresh_colors()

func activate_attack_hitbox(data: MonsterAttackData) -> void:
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = data.hitbox_size
	_attack_hitbox_shape.shape = shape
	_attack_hitbox_shape.position = data.hitbox_offset
	_attack_hitbox.damage = data.damage
	_attack_hitbox.hitstop_ms = data.hitstop_ms
	_attack_hitbox.screen_shake_amplitude = data.screen_shake_amplitude
	_attack_hitbox.stagger = true
	_attack_hitbox.activate()

func deactivate_attack_hitbox() -> void:
	_attack_hitbox.deactivate()

func start_cooldown(label: String, seconds: float) -> void:
	_cooldowns[label] = seconds * (0.7 if phase == 2 else 1.0)

func should_rest() -> bool:
	_since_exhaustion_reset += 1
	if _since_exhaustion_reset >= exhaustion_trigger_count:
		_since_exhaustion_reset = 0
		return true
	return false

func on_died() -> void:
	pass

func respawn() -> void:
	global_transform = _spawn_transform
	total_health = max_health
	head_hp = HEAD_HP
	tail_hp = TAIL_HP
	head_broken = false
	tail_broken = false
	phase = 1
	_cooldowns.clear()
	_since_exhaustion_reset = 0
	velocity = Vector3.ZERO
	_refresh_colors()
	health_changed.emit(total_health, max_health)
	phase_changed.emit(phase)

func current_state_name() -> String:
	return _state_machine.current_name()

func _on_hurtbox_hit(event: DamageEvent, hurtbox: Hurtbox) -> void:
	var amount: float = event.amount
	total_health = maxf(0.0, total_health - amount)
	var push: Vector3 = Vector3(event.direction.x, 0.0, event.direction.z)
	if push.length() > 0.01:
		push = push.normalized() * knockback_impulse
		velocity.x += push.x
		velocity.z += push.z
	if hurtbox.name == "HeadHurtbox" and not head_broken:
		head_hp = maxf(0.0, head_hp - amount)
		if head_hp <= 0.0:
			head_broken = true
			part_broken.emit("head")
	elif hurtbox.name == "TailHurtbox" and not tail_broken:
		tail_hp = maxf(0.0, tail_hp - amount)
		if tail_hp <= 0.0:
			tail_broken = true
			part_broken.emit("tail")

	if phase == 1 and total_health <= max_health * phase2_threshold and total_health > 0.0:
		phase = 2
		phase_changed.emit(phase)
	_refresh_colors()
	health_changed.emit(total_health, max_health)

	if total_health <= 0.0 and current_state_name() != "Dying":
		_state_machine.change_to("Dying")

func _on_state_changed(state_name: String) -> void:
	state_changed.emit(state_name)

func _refresh_colors() -> void:
	if _telegraph_active:
		return
	var base: Color = ENRAGED_COLOR if phase == 2 else NORMAL_COLOR
	_torso_material.albedo_color = base
	_torso_material.emission_enabled = phase == 2
	_torso_material.emission = base
	_torso_material.emission_energy_multiplier = 0.25 if phase == 2 else 0.0

	if head_broken:
		_head_material.albedo_color = BROKEN_COLOR
		_head_material.emission_enabled = false
	else:
		_head_material.albedo_color = WEAK_COLOR
		_head_material.emission_enabled = true
		_head_material.emission = WEAK_COLOR
		_head_material.emission_energy_multiplier = 0.4

	if tail_broken:
		_tail_material.albedo_color = BROKEN_COLOR
		_tail_material.emission_enabled = false
	else:
		_tail_material.albedo_color = WEAK_COLOR
		_tail_material.emission_enabled = true
		_tail_material.emission = WEAK_COLOR
		_tail_material.emission_energy_multiplier = 0.4

func _mat_for(mi: MeshInstance3D) -> StandardMaterial3D:
	var existing: Material = mi.get_surface_override_material(0)
	if existing is StandardMaterial3D:
		var sm: StandardMaterial3D = existing as StandardMaterial3D
		mi.set_surface_override_material(0, sm)
		return sm
	var sm2: StandardMaterial3D = StandardMaterial3D.new()
	sm2.albedo_color = NORMAL_COLOR
	mi.set_surface_override_material(0, sm2)
	return sm2

func _build_attacks() -> Array[MonsterAttackData]:
	var swipe := MonsterAttackData.new()
	swipe.label = "Swipe"
	swipe.telegraph_time = 0.55
	swipe.active_time = 0.18
	swipe.recovery_time = 0.6
	swipe.damage = 18.0
	swipe.hitstop_ms = 80.0
	swipe.screen_shake_amplitude = 0.45
	swipe.min_range = 0.0
	swipe.max_range = 4.5
	swipe.cooldown = 2.0
	swipe.advance_distance = 1.2
	swipe.hitbox_offset = Vector3(0.0, 1.4, -2.2)
	swipe.hitbox_size = Vector3(3.0, 1.8, 3.6)
	swipe.telegraph_color = Color(1, 0.55, 0.25, 1)

	var slam := MonsterAttackData.new()
	slam.label = "Slam"
	slam.telegraph_time = 0.85
	slam.active_time = 0.24
	slam.recovery_time = 0.9
	slam.damage = 28.0
	slam.hitstop_ms = 110.0
	slam.screen_shake_amplitude = 0.8
	slam.min_range = 0.0
	slam.max_range = 3.8
	slam.cooldown = 3.5
	slam.advance_distance = 0.4
	slam.hitbox_offset = Vector3(0.0, 0.5, -1.2)
	slam.hitbox_size = Vector3(4.5, 1.2, 4.5)
	slam.telegraph_color = Color(1, 0.25, 0.25, 1)

	var charge := MonsterAttackData.new()
	charge.label = "Charge"
	charge.telegraph_time = 0.75
	charge.active_time = 0.35
	charge.recovery_time = 1.0
	charge.damage = 32.0
	charge.hitstop_ms = 120.0
	charge.screen_shake_amplitude = 0.75
	charge.min_range = 3.0
	charge.max_range = 10.0
	charge.cooldown = 4.0
	charge.advance_distance = 7.0
	charge.hitbox_offset = Vector3(0.0, 1.2, -1.6)
	charge.hitbox_size = Vector3(2.6, 2.2, 3.6)
	charge.telegraph_color = Color(1, 0.4, 0.15, 1)
	charge.requires_head = true

	var tail_sweep := MonsterAttackData.new()
	tail_sweep.label = "TailSweep"
	tail_sweep.telegraph_time = 0.6
	tail_sweep.active_time = 0.28
	tail_sweep.recovery_time = 0.65
	tail_sweep.damage = 22.0
	tail_sweep.hitstop_ms = 90.0
	tail_sweep.screen_shake_amplitude = 0.55
	tail_sweep.min_range = 0.0
	tail_sweep.max_range = 5.2
	tail_sweep.cooldown = 2.5
	tail_sweep.advance_distance = 0.6
	tail_sweep.hitbox_offset = Vector3(0.0, 0.7, 2.8)
	tail_sweep.hitbox_size = Vector3(4.0, 1.0, 4.5)
	tail_sweep.telegraph_color = Color(1, 0.65, 0.3, 1)
	tail_sweep.requires_tail = true

	return [swipe, slam, charge, tail_sweep]
