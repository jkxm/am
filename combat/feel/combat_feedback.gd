class_name CombatFeedback
extends Node

const HIT_SPARKS_SCENE: PackedScene = preload("res://combat/feel/hit_sparks.tscn")
const SLAM_RING_SCENE: PackedScene = preload("res://combat/feel/slam_ring.tscn")
const ImpactLinesScript: GDScript = preload("res://combat/feel/impact_lines.gd")

@export_group("Hit")
@export var slam_level_threshold: int = 3

@export_group("Screen")
@export var armored_flash_color: Color = Color(0.3, 0.6, 1.0, 0.35)
@export var armored_flash_duration: float = 0.12
@export var unarmored_flash_color: Color = Color(1.0, 0.1, 0.0, 0.5)
@export var unarmored_flash_duration: float = 0.18
@export var armor_break_flash_color: Color = Color(0.6, 0.85, 1.0, 0.55)
@export var armor_break_flash_duration: float = 0.18
@export var armor_restored_flash_color: Color = Color(0.55, 0.8, 1.0, 0.25)
@export var armor_restored_flash_duration: float = 0.15

@export_group("Aberration")
@export var unarmored_aberration: float = 0.006

@export_group("Slowmo")
@export var armor_break_slowmo_scale: float = 0.3
@export var armor_break_slowmo_duration: float = 0.15
@export var critical_slowmo_scale: float = 0.2
@export var critical_slowmo_duration: float = 0.3

@export_group("Low Health")
@export var low_health_threshold: float = 0.3
@export var critical_health_threshold: float = 0.1
@export var low_health_vignette_base: float = 0.25
@export var low_health_vignette_amp: float = 0.1
@export var low_health_vignette_speed: float = 2.2
@export var low_health_vignette_color: Color = Color(0.8, 0.05, 0.02, 1.0)

@export_group("Shake")
@export var armored_hit_shake: float = 0.12
@export var unarmored_hit_shake: float = 0.45
@export var critical_hit_shake_mult: float = 2.0
@export var armor_break_shake: float = 0.3

@export var camera_path: NodePath
@export var player_path: NodePath

var _camera: CombatCamera = null
var _player_health_ratio: float = 1.0
var _armor_was_up: bool = true
var _in_low_health: bool = false

func _ready() -> void:
	if camera_path != NodePath():
		_camera = get_node_or_null(camera_path) as CombatCamera
	GameEvents.player_hit_landed_at.connect(_on_hit_landed_at)
	GameEvents.player_took_hit.connect(_on_player_took_hit)
	GameEvents.player_armor_state_changed.connect(_on_armor_state_changed)
	GameEvents.player_health_changed.connect(_on_player_health_changed)
	GameEvents.player_slam_impact.connect(_on_slam_impact)
	GameEvents.player_knockback_delivered.connect(_on_knockback_delivered)

func _on_hit_landed_at(point: Vector3, normal: Vector3, charge_level: int) -> void:
	_spawn_sparks(point, normal, charge_level)
	if charge_level >= slam_level_threshold:
		_spawn_slam_ring(point, 3.0 + 0.5 * charge_level)
	if _camera != null and charge_level >= 2:
		_camera.trigger_cinematic_hit(point, charge_level)

func _spawn_sparks(point: Vector3, normal: Vector3, charge_level: int) -> void:
	var sparks: HitSparks = HIT_SPARKS_SCENE.instantiate()
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(sparks)
	sparks.global_position = point
	sparks.configure(charge_level, normal)

func _spawn_slam_ring(point: Vector3, radius: float) -> void:
	var ring: SlamRing = SLAM_RING_SCENE.instantiate()
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(ring)
	ring.global_position = Vector3(point.x, _ground_y_at(point), point.z)
	ring.max_radius = radius

func _ground_y_at(from: Vector3) -> float:
	var space: PhysicsDirectSpaceState3D = get_viewport().world_3d.direct_space_state if get_viewport() != null else null
	if space == null:
		return from.y
	var q := PhysicsRayQueryParameters3D.create(from + Vector3(0, 1.0, 0), from + Vector3(0, -8.0, 0), 1)
	var r: Dictionary = space.intersect_ray(q)
	if r.is_empty():
		return from.y
	return r.position.y + 0.01

func _on_player_took_hit(damage: float, armored: bool) -> void:
	var se: ScreenEffects = ScreenEffects.get_instance()
	if armored:
		if se != null:
			se.flash(armored_flash_color, armored_flash_duration)
		if _camera != null:
			_camera.shake(armored_hit_shake)
		return
	var shake_amount: float = unarmored_hit_shake
	if _player_health_ratio <= critical_health_threshold:
		shake_amount *= critical_hit_shake_mult
		Slowmo.apply(critical_slowmo_scale, critical_slowmo_duration)
	if se != null:
		se.flash(unarmored_flash_color, unarmored_flash_duration)
		se.spike_aberration(unarmored_aberration)
	if _camera != null:
		_camera.shake(shake_amount)
	if Engine.has_singleton("Input"):
		pass
	_rumble(0.5, 0.2)

func _on_armor_state_changed(is_up: bool) -> void:
	var se: ScreenEffects = ScreenEffects.get_instance()
	if not is_up and _armor_was_up:
		if se != null:
			se.flash(armor_break_flash_color, armor_break_flash_duration)
		if _camera != null:
			_camera.shake(armor_break_shake)
		Slowmo.apply(armor_break_slowmo_scale, armor_break_slowmo_duration)
	elif is_up and not _armor_was_up:
		if se != null:
			se.flash(armor_restored_flash_color, armor_restored_flash_duration)
	_armor_was_up = is_up

func _on_player_health_changed(current: float, maximum: float) -> void:
	_player_health_ratio = current / maxf(maximum, 0.001)
	var se: ScreenEffects = ScreenEffects.get_instance()
	if se == null:
		return
	if _player_health_ratio <= low_health_threshold and _player_health_ratio > 0.0:
		if not _in_low_health:
			_in_low_health = true
		var t: float = clampf(_player_health_ratio / low_health_threshold, 0.0, 1.0)
		var base: float = lerpf(low_health_vignette_base * 1.4, low_health_vignette_base * 0.8, t)
		var amp: float = lerpf(low_health_vignette_amp * 1.5, low_health_vignette_amp, t)
		var speed: float = lerpf(low_health_vignette_speed * 1.8, low_health_vignette_speed, t)
		se.pulse_vignette(base, amp, speed, low_health_vignette_color)
	else:
		if _in_low_health:
			_in_low_health = false
			se.clear_vignette()

func _on_slam_impact(point: Vector3, radius: float) -> void:
	_spawn_slam_ring(point, radius)
	if _camera != null:
		_camera.shake(0.7)

func _on_knockback_delivered(point: Vector3, direction: Vector3, effective_force: float, resisted: bool, charge_level: int) -> void:
	if effective_force < 0.01 or charge_level <= 0:
		return
	var lines := ImpactLines.new()
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_parent()
	host.add_child(lines)
	lines.global_position = point
	var length: float = clampf(0.6 + 0.4 * float(charge_level) + effective_force * 0.05, 0.6, 2.5)
	var line_color: Color = Color(1.0, 0.95, 0.7, 0.9) if not resisted else Color(0.75, 0.75, 0.8, 0.6)
	lines.configure(direction, length, line_color)
	if _camera != null:
		_camera.shake(clampf(effective_force * 0.04, 0.1, 0.9))

func _rumble(strength: float, duration: float) -> void:
	Input.start_joy_vibration(0, strength * 0.6, strength, duration)
