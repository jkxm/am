class_name ThreatReticle
extends Node3D

@export var color: Color = Color(1.0, 0.25, 0.2, 0.55)
@export var radius: float = 2.0
@export var tracking_fraction: float = 0.5
@export var appear_duration: float = 0.08
@export var fade_duration: float = 0.18

var total_duration: float = 0.8
var target: Node3D = null
var _elapsed: float = 0.0
var _expired: bool = false

@onready var _ring: CSGTorus3D = $Ring
@onready var _inner: CSGCylinder3D = $Inner

func configure(p_target: Node3D, p_radius: float, p_total: float, p_color: Color) -> void:
	target = p_target
	radius = p_radius
	total_duration = p_total
	color = p_color
	_apply_radius()
	_apply_color()

func _ready() -> void:
	_apply_radius()
	_apply_color()

func _apply_radius() -> void:
	if _ring != null:
		_ring.outer_radius = radius
		_ring.inner_radius = maxf(radius - 0.15, 0.05)
	if _inner != null:
		_inner.radius = radius

func _apply_color() -> void:
	if _ring != null:
		var m: StandardMaterial3D = _ring.material as StandardMaterial3D
		if m != null:
			m.albedo_color = color
			m.emission = color
	if _inner != null:
		var mi: StandardMaterial3D = _inner.material as StandardMaterial3D
		if mi != null:
			var c: Color = color
			c.a *= 0.35
			mi.albedo_color = c

func _process(delta: float) -> void:
	_elapsed += delta
	if not _expired and target != null and is_instance_valid(target):
		var tracking_time: float = total_duration * tracking_fraction
		if _elapsed < tracking_time:
			var tp: Vector3 = target.global_position
			global_position = Vector3(tp.x, global_position.y, tp.z)

	var alpha_scale: float = 1.0
	if _elapsed < appear_duration:
		alpha_scale = _elapsed / maxf(appear_duration, 0.001)
	elif _expired:
		var fade_t: float = clampf((_elapsed - _expire_start) / maxf(fade_duration, 0.001), 0.0, 1.0)
		alpha_scale = 1.0 - fade_t
	_apply_alpha(alpha_scale)

	if _expired and _elapsed - _expire_start >= fade_duration:
		queue_free()
		return
	if not _expired and _elapsed >= total_duration:
		expire()

var _expire_start: float = 0.0

func expire() -> void:
	if _expired:
		return
	_expired = true
	_expire_start = _elapsed

func _apply_alpha(scale: float) -> void:
	if _ring != null:
		var m: StandardMaterial3D = _ring.material as StandardMaterial3D
		if m != null:
			var c: Color = color
			c.a *= scale
			m.albedo_color = c
	if _inner != null:
		var mi: StandardMaterial3D = _inner.material as StandardMaterial3D
		if mi != null:
			var c2: Color = color
			c2.a *= 0.35 * scale
			mi.albedo_color = c2
