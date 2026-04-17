class_name Player
extends CharacterBody3D

@export_group("Locomotion")
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.5
@export var ground_accel: float = 40.0
@export var air_accel: float = 12.0
@export var turn_speed: float = 12.0
@export var jump_velocity: float = 6.0
@export var gravity: float = 22.0
@export var terminal_velocity: float = 30.0

@export_group("Dodge")
@export var dodge_stamina_cost: float = 20.0

@export_group("Camera")
@export var camera_rig_path: NodePath

@export_group("Healing")
@export var heal_amount: float = 30.0
@export var heal_duration: float = 0.8

@export_group("Debug")
@export var debug_damage_amount: float = 25.0

@onready var stamina: Stamina = $Stamina
@onready var enhanced_resource: EnhancedResource = $EnhancedResource
@onready var armor: Armor = $Armor
@onready var health: Health = $Health
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var mesh_root: Node3D = $MeshRoot
@onready var wall_detector: WallDetector = $WallDetector
@onready var heavy_weapon: HeavyWeapon = $MeshRoot/HeavyWeapon
@onready var charge_glow: OmniLight3D = get_node_or_null("MeshRoot/SwordMesh/ChargeGlow")
@onready var trajectory_preview: TrajectoryPreview = $TrajectoryPreview

var camera_rig: CombatCamera = null
var invulnerable: bool = false
var is_vulnerable: bool = false
var pending_attack: AttackData = null
var last_hit_direction: Vector3 = Vector3.ZERO
var _heal_timer: float = 0.0

const STATE_TO_CONTEXT: Dictionary = {
	"Idle": &"ground",
	"WalkRun": &"ground",
	"DodgeRoll": &"ground",
	"Attack": &"ground",
	"ChargeAttack": &"ground",
	"Stagger": &"ground",
	"JumpFall": &"air",
	"AirDash": &"air",
	"AerialAttack": &"air",
	"WallJump": &"air",
	"ChargeWallAttack": &"air",
	"WallRun": &"wall",
	"WallDash": &"wall",
	"WallCling": &"wall",
}

func _ready() -> void:
	camera_rig = get_node_or_null(camera_rig_path) as CombatCamera
	state_machine.setup(self)
	state_machine.state_changed.connect(_on_state_changed)
	stamina.changed.connect(_on_stamina_changed)
	enhanced_resource.changed.connect(_on_enhanced_changed)
	armor.state_changed.connect(_on_armor_state_changed)
	armor.regen_changed.connect(_on_armor_regen_changed)
	health.changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	hurtbox.owner_ref = self
	hurtbox.hit_received.connect(_on_hit_received)
	heavy_weapon.hitbox.source = self

func _on_state_changed(state_name: String) -> void:
	GameEvents.player_state_changed.emit(state_name)
	if camera_rig != null:
		var context: StringName = STATE_TO_CONTEXT.get(state_name, &"ground")
		camera_rig.set_context(context)

func _on_stamina_changed(current: float, maximum: float) -> void:
	GameEvents.player_stamina_changed.emit(current, maximum)

func _on_enhanced_changed(current: float, maximum: float) -> void:
	GameEvents.player_enhanced_changed.emit(current, maximum)

func _on_armor_state_changed(is_up: bool) -> void:
	GameEvents.player_armor_state_changed.emit(is_up)

func _on_armor_regen_changed(progress: float) -> void:
	GameEvents.player_armor_regen_changed.emit(progress)

func _on_health_changed(current: float, maximum: float) -> void:
	GameEvents.player_health_changed.emit(current, maximum)

func _on_died() -> void:
	GameEvents.player_died.emit()
	health.revive()
	armor.accelerate()

func _on_hit_received(event: DamageEvent) -> void:
	if invulnerable:
		return
	last_hit_direction = event.direction
	var armored: bool = armor.absorb_hit()
	if armored:
		GameEvents.player_took_hit.emit(event.amount, true)
		return
	health.damage(event.amount)
	GameEvents.player_took_hit.emit(event.amount, false)
	if health.is_alive():
		state_machine.change_to("Stagger")

func take_environmental_damage(amount: float) -> void:
	if invulnerable or amount <= 0.0:
		return
	health.damage(amount)
	GameEvents.player_took_hit.emit(amount, false)

func active_attack_data() -> AttackData:
	if state_machine == null:
		return null
	var cur: Node = state_machine._current
	if cur == null:
		return null
	if "_data" in cur:
		var d: Variant = cur.get("_data")
		if d is AttackData:
			return d as AttackData
	return null

func _physics_process(delta: float) -> void:
	wall_detector.update()
	_process_heal(delta)
	_process_debug_input()
	state_machine.physics_step(delta)

func _process_heal(delta: float) -> void:
	if _heal_timer > 0.0:
		_heal_timer = maxf(0.0, _heal_timer - delta)
		return
	if InputMap.has_action("heal") and Input.is_action_just_pressed("heal"):
		if is_on_floor() and health.is_alive():
			health.heal(heal_amount)
			armor.accelerate()
			_heal_timer = heal_duration

func _process_debug_input() -> void:
	if InputMap.has_action("debug_damage") and Input.is_action_just_pressed("debug_damage"):
		var event := DamageEvent.new()
		event.amount = debug_damage_amount
		event.source = null
		event.direction = -mesh_root.global_transform.basis.z
		event.stagger = true
		_on_hit_received(event)

func read_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_back", "move_forward")

func camera_relative_direction(move_input: Vector2) -> Vector3:
	if move_input.length() < 0.01:
		return Vector3.ZERO
	var basis := camera_rig.get_yaw_basis()
	var forward := -basis.z
	var right := basis.x
	var dir := right * move_input.x + forward * move_input.y
	dir.y = 0.0
	return dir.normalized() * move_input.length()

func face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() < 0.01:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_yaw, clampf(turn_speed * delta, 0.0, 1.0))

func apply_gravity(delta: float) -> void:
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = -1.0
		return
	velocity.y = maxf(velocity.y - gravity * delta, -terminal_velocity)

func apply_ground_friction(delta: float) -> void:
	if not is_on_floor():
		return
	velocity.x = move_toward(velocity.x, 0.0, ground_accel * delta)
	velocity.z = move_toward(velocity.z, 0.0, ground_accel * delta)

func do_jump() -> void:
	velocity.y = jump_velocity

func on_landed_hit() -> void:
	enhanced_resource.gain_from_hit()
	armor.accelerate()
	GameEvents.player_landed_hit.emit(heavy_weapon.hitbox.damage)
