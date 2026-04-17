class_name HeavyWeapon
extends Node3D

@export_group("Charge Thresholds")
@export var charge_time_level_1: float = 0.4
@export var charge_time_level_2: float = 1.0
@export var charge_time_level_3: float = 1.8

@export_group("Charge Behavior")
@export var charge_aim_rotation_speed_deg: float = 45.0
@export var air_charge_horizontal_drift: float = 2.0
@export var air_charge_fall_speed: float = 3.0
@export var wall_launch_min_angle_deg: float = 15.0
@export var wall_launch_gravity_delay: float = 0.15

@export_group("Ground Hitbox")
@export var ground_hitbox_size: Vector3 = Vector3(2.0, 1.5, 3.0)
@export var ground_hitbox_offset: Vector3 = Vector3(0.0, 1.0, -1.5)

@export_group("Ground L0")
@export var ground_l0_anticipation: float = 0.15
@export var ground_l0_active: float = 0.12
@export var ground_l0_recovery: float = 0.3
@export var ground_l0_damage: float = 30.0
@export var ground_l0_hitstop: float = 0.04
@export var ground_l0_screenshake: float = 0.1
@export var ground_l0_forward_motion: float = 1.0
@export var ground_l0_has_cancel: bool = true

@export_group("Ground L1")
@export var ground_l1_anticipation: float = 0.25
@export var ground_l1_active: float = 0.15
@export var ground_l1_recovery: float = 0.5
@export var ground_l1_damage: float = 70.0
@export var ground_l1_hitstop: float = 0.06
@export var ground_l1_screenshake: float = 0.2
@export var ground_l1_forward_motion: float = 1.5
@export var ground_l1_has_cancel: bool = true

@export_group("Ground L2")
@export var ground_l2_anticipation: float = 0.3
@export var ground_l2_active: float = 0.18
@export var ground_l2_recovery: float = 0.7
@export var ground_l2_damage: float = 120.0
@export var ground_l2_hitstop: float = 0.08
@export var ground_l2_screenshake: float = 0.35
@export var ground_l2_forward_motion: float = 2.0
@export var ground_l2_has_cancel: bool = true

@export_group("Ground L3")
@export var ground_l3_anticipation: float = 0.35
@export var ground_l3_active: float = 0.2
@export var ground_l3_recovery: float = 1.0
@export var ground_l3_damage: float = 200.0
@export var ground_l3_hitstop: float = 0.12
@export var ground_l3_screenshake: float = 0.5
@export var ground_l3_forward_motion: float = 2.5
@export var ground_l3_has_cancel: bool = false

@export_group("Wall Hitbox")
@export var wall_hitbox_size: Vector3 = Vector3(2.0, 1.4, 2.8)
@export var wall_hitbox_offset: Vector3 = Vector3(0.0, 1.0, -1.5)
@export var wall_launch_speed: float = 22.0

@export_group("Wall L0")
@export var wall_l0_launch_distance: float = 3.0
@export var wall_l0_damage: float = 35.0
@export var wall_l0_active: float = 0.15
@export var wall_l0_recovery: float = 0.4
@export var wall_l0_hitstop: float = 0.04
@export var wall_l0_screenshake: float = 0.1
@export var wall_l0_has_cancel: bool = true

@export_group("Wall L1")
@export var wall_l1_launch_distance: float = 5.0
@export var wall_l1_damage: float = 80.0
@export var wall_l1_active: float = 0.18
@export var wall_l1_recovery: float = 0.6
@export var wall_l1_hitstop: float = 0.07
@export var wall_l1_screenshake: float = 0.25
@export var wall_l1_has_cancel: bool = true

@export_group("Wall L2")
@export var wall_l2_launch_distance: float = 8.0
@export var wall_l2_damage: float = 140.0
@export var wall_l2_active: float = 0.2
@export var wall_l2_recovery: float = 0.8
@export var wall_l2_hitstop: float = 0.09
@export var wall_l2_screenshake: float = 0.4
@export var wall_l2_has_cancel: bool = true

@export_group("Wall L3")
@export var wall_l3_launch_distance: float = 12.0
@export var wall_l3_damage: float = 220.0
@export var wall_l3_active: float = 0.22
@export var wall_l3_recovery: float = 1.1
@export var wall_l3_hitstop: float = 0.12
@export var wall_l3_screenshake: float = 0.55
@export var wall_l3_has_cancel: bool = false

@export_group("Air Hitbox")
@export var air_slam_descent_hitbox_offset: Vector3 = Vector3(0.0, 0.6, -0.1)
@export var air_slam_descent_hitbox_size: Vector3 = Vector3(1.6, 1.0, 1.6)

@export_group("Air L0")
@export var air_l0_slam_speed: float = 15.0
@export var air_l0_damage: float = 40.0
@export var air_l0_impact_radius: float = 1.0
@export var air_l0_recovery: float = 0.5
@export var air_l0_hitstop: float = 0.05
@export var air_l0_screenshake: float = 0.15
@export var air_l0_has_cancel: bool = true

@export_group("Air L1")
@export var air_l1_slam_speed: float = 20.0
@export var air_l1_damage: float = 90.0
@export var air_l1_impact_radius: float = 1.5
@export var air_l1_recovery: float = 0.7
@export var air_l1_hitstop: float = 0.08
@export var air_l1_screenshake: float = 0.3
@export var air_l1_has_cancel: bool = true

@export_group("Air L2")
@export var air_l2_slam_speed: float = 25.0
@export var air_l2_damage: float = 160.0
@export var air_l2_impact_radius: float = 2.0
@export var air_l2_recovery: float = 0.9
@export var air_l2_hitstop: float = 0.1
@export var air_l2_screenshake: float = 0.45
@export var air_l2_has_cancel: bool = true

@export_group("Air L3")
@export var air_l3_slam_speed: float = 30.0
@export var air_l3_damage: float = 250.0
@export var air_l3_impact_radius: float = 2.5
@export var air_l3_recovery: float = 1.2
@export var air_l3_hitstop: float = 0.14
@export var air_l3_screenshake: float = 0.6
@export var air_l3_has_cancel: bool = false

@export_group("Cancel Window")
@export var cancel_window_duration: float = 0.15

@export_group("Stamina")
@export var ground_stamina_l0: float = 6.0
@export var ground_stamina_l1: float = 10.0
@export var ground_stamina_l2: float = 16.0
@export var ground_stamina_l3: float = 24.0

@onready var hitbox: Hitbox = $Hitbox
@onready var _hitbox_shape: CollisionShape3D = $Hitbox/CollisionShape3D

func _ready() -> void:
	hitbox.deactivate()

func charge_level_for(hold_time: float) -> int:
	if hold_time >= charge_time_level_3:
		return 3
	if hold_time >= charge_time_level_2:
		return 2
	if hold_time >= charge_time_level_1:
		return 1
	return 0

func charge_progress(hold_time: float) -> float:
	if hold_time < charge_time_level_1:
		return hold_time / maxf(charge_time_level_1, 0.001) * 0.333
	if hold_time < charge_time_level_2:
		return 0.333 + (hold_time - charge_time_level_1) / maxf(charge_time_level_2 - charge_time_level_1, 0.001) * 0.333
	if hold_time < charge_time_level_3:
		return 0.666 + (hold_time - charge_time_level_2) / maxf(charge_time_level_3 - charge_time_level_2, 0.001) * 0.334
	return 1.0

func get_ground_attack(level: int) -> AttackData:
	var d := AttackData.new()
	d.charge_level = level
	d.hitbox_offset = ground_hitbox_offset
	d.hitbox_size = ground_hitbox_size
	d.cancel_window_duration = cancel_window_duration
	d.cancel_window_start_frac = 0.6
	match level:
		0:
			d.label = "Ground L0"
			d.windup_time = ground_l0_anticipation
			d.active_time = ground_l0_active
			d.recovery_time = ground_l0_recovery
			d.damage = ground_l0_damage
			d.hitstop_ms = ground_l0_hitstop * 1000.0
			d.screen_shake_amplitude = ground_l0_screenshake
			d.forward_motion = ground_l0_forward_motion
			d.has_cancel_window = ground_l0_has_cancel
			d.stamina_cost = ground_stamina_l0
		1:
			d.label = "Ground L1"
			d.windup_time = ground_l1_anticipation
			d.active_time = ground_l1_active
			d.recovery_time = ground_l1_recovery
			d.damage = ground_l1_damage
			d.hitstop_ms = ground_l1_hitstop * 1000.0
			d.screen_shake_amplitude = ground_l1_screenshake
			d.forward_motion = ground_l1_forward_motion
			d.has_cancel_window = ground_l1_has_cancel
			d.stamina_cost = ground_stamina_l1
		2:
			d.label = "Ground L2"
			d.windup_time = ground_l2_anticipation
			d.active_time = ground_l2_active
			d.recovery_time = ground_l2_recovery
			d.damage = ground_l2_damage
			d.hitstop_ms = ground_l2_hitstop * 1000.0
			d.screen_shake_amplitude = ground_l2_screenshake
			d.forward_motion = ground_l2_forward_motion
			d.has_cancel_window = ground_l2_has_cancel
			d.stamina_cost = ground_stamina_l2
		_:
			d.label = "Ground L3"
			d.windup_time = ground_l3_anticipation
			d.active_time = ground_l3_active
			d.recovery_time = ground_l3_recovery
			d.damage = ground_l3_damage
			d.hitstop_ms = ground_l3_hitstop * 1000.0
			d.screen_shake_amplitude = ground_l3_screenshake
			d.forward_motion = ground_l3_forward_motion
			d.has_cancel_window = ground_l3_has_cancel
			d.stamina_cost = ground_stamina_l3
	d.enhanced_gain_on_hit = 10.0 + 6.0 * float(level)
	return d

func get_wall_attack(level: int) -> AttackData:
	var d := AttackData.new()
	d.charge_level = level
	d.hitbox_offset = wall_hitbox_offset
	d.hitbox_size = wall_hitbox_size
	d.cancel_window_duration = cancel_window_duration
	d.cancel_window_start_frac = 0.6
	d.launch_speed = wall_launch_speed
	d.windup_time = 0.1
	match level:
		0:
			d.label = "Wall L0"
			d.launch_distance = wall_l0_launch_distance
			d.active_time = wall_l0_active
			d.recovery_time = wall_l0_recovery
			d.damage = wall_l0_damage
			d.hitstop_ms = wall_l0_hitstop * 1000.0
			d.screen_shake_amplitude = wall_l0_screenshake
			d.has_cancel_window = wall_l0_has_cancel
			d.stamina_cost = ground_stamina_l0
		1:
			d.label = "Wall L1"
			d.launch_distance = wall_l1_launch_distance
			d.active_time = wall_l1_active
			d.recovery_time = wall_l1_recovery
			d.damage = wall_l1_damage
			d.hitstop_ms = wall_l1_hitstop * 1000.0
			d.screen_shake_amplitude = wall_l1_screenshake
			d.has_cancel_window = wall_l1_has_cancel
			d.stamina_cost = ground_stamina_l1
		2:
			d.label = "Wall L2"
			d.launch_distance = wall_l2_launch_distance
			d.active_time = wall_l2_active
			d.recovery_time = wall_l2_recovery
			d.damage = wall_l2_damage
			d.hitstop_ms = wall_l2_hitstop * 1000.0
			d.screen_shake_amplitude = wall_l2_screenshake
			d.has_cancel_window = wall_l2_has_cancel
			d.stamina_cost = ground_stamina_l2
		_:
			d.label = "Wall L3"
			d.launch_distance = wall_l3_launch_distance
			d.active_time = wall_l3_active
			d.recovery_time = wall_l3_recovery
			d.damage = wall_l3_damage
			d.hitstop_ms = wall_l3_hitstop * 1000.0
			d.screen_shake_amplitude = wall_l3_screenshake
			d.has_cancel_window = wall_l3_has_cancel
			d.stamina_cost = ground_stamina_l3
	d.enhanced_gain_on_hit = 12.0 + 7.0 * float(level)
	return d

func get_air_attack(level: int) -> AttackData:
	var d := AttackData.new()
	d.charge_level = level
	d.hitbox_offset = air_slam_descent_hitbox_offset
	d.hitbox_size = air_slam_descent_hitbox_size
	d.cancel_window_duration = cancel_window_duration
	d.cancel_window_start_frac = 0.5
	d.windup_time = 0.08
	d.active_time = 0.4
	match level:
		0:
			d.label = "Air L0"
			d.slam_speed = air_l0_slam_speed
			d.damage = air_l0_damage
			d.impact_radius = air_l0_impact_radius
			d.recovery_time = air_l0_recovery
			d.hitstop_ms = air_l0_hitstop * 1000.0
			d.screen_shake_amplitude = air_l0_screenshake
			d.has_cancel_window = air_l0_has_cancel
			d.stamina_cost = ground_stamina_l0
		1:
			d.label = "Air L1"
			d.slam_speed = air_l1_slam_speed
			d.damage = air_l1_damage
			d.impact_radius = air_l1_impact_radius
			d.recovery_time = air_l1_recovery
			d.hitstop_ms = air_l1_hitstop * 1000.0
			d.screen_shake_amplitude = air_l1_screenshake
			d.has_cancel_window = air_l1_has_cancel
			d.stamina_cost = ground_stamina_l1
		2:
			d.label = "Air L2"
			d.slam_speed = air_l2_slam_speed
			d.damage = air_l2_damage
			d.impact_radius = air_l2_impact_radius
			d.recovery_time = air_l2_recovery
			d.hitstop_ms = air_l2_hitstop * 1000.0
			d.screen_shake_amplitude = air_l2_screenshake
			d.has_cancel_window = air_l2_has_cancel
			d.stamina_cost = ground_stamina_l2
		_:
			d.label = "Air L3"
			d.slam_speed = air_l3_slam_speed
			d.damage = air_l3_damage
			d.impact_radius = air_l3_impact_radius
			d.recovery_time = air_l3_recovery
			d.hitstop_ms = air_l3_hitstop * 1000.0
			d.screen_shake_amplitude = air_l3_screenshake
			d.has_cancel_window = air_l3_has_cancel
			d.stamina_cost = ground_stamina_l3
	d.vertical_motion = -d.slam_speed
	d.enhanced_gain_on_hit = 14.0 + 8.0 * float(level)
	return d

func activate_hitbox(data: AttackData) -> void:
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = data.hitbox_size
	_hitbox_shape.shape = shape
	_hitbox_shape.position = data.hitbox_offset
	hitbox.damage = data.damage
	hitbox.hitstop_ms = data.hitstop_ms
	hitbox.screen_shake_amplitude = data.screen_shake_amplitude
	hitbox.stagger = true
	hitbox.activate()

func activate_aoe_hitbox(data: AttackData, origin: Vector3) -> void:
	var sphere := SphereShape3D.new()
	sphere.radius = data.impact_radius
	_hitbox_shape.shape = sphere
	_hitbox_shape.global_position = origin
	hitbox.damage = data.damage
	hitbox.hitstop_ms = data.hitstop_ms
	hitbox.screen_shake_amplitude = data.screen_shake_amplitude
	hitbox.stagger = true
	hitbox.activate()

func deactivate_hitbox() -> void:
	hitbox.deactivate()
