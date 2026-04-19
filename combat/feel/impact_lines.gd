class_name ImpactLines
extends Node3D

@export var line_count: int = 4
@export var line_length: float = 1.5
@export var line_width: float = 0.05
@export var spread_angle_deg: float = 18.0
@export var appear_duration: float = 0.07
@export var fade_duration: float = 0.15
@export var color: Color = Color(1.0, 0.95, 0.75, 0.95)

var _elapsed: float = 0.0
var _lines: Array[Node3D] = []
var _material: StandardMaterial3D = null

func configure(direction: Vector3, new_length: float, new_color: Color) -> void:
	line_length = new_length
	color = new_color
	_build(direction)

func _build(direction: Vector3) -> void:
	if direction.length() < 0.001:
		direction = Vector3(0, 1, 0)
	direction = direction.normalized()
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	_material.emission_enabled = true
	_material.emission = color
	_material.emission_energy_multiplier = 2.5
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var base_basis: Basis = _basis_from_forward(direction)
	for i in range(line_count):
		var jitter_y: float = randf_range(-spread_angle_deg, spread_angle_deg)
		var jitter_x: float = randf_range(-spread_angle_deg, spread_angle_deg)
		var rot: Basis = base_basis * Basis(Vector3.UP, deg_to_rad(jitter_y)) * Basis(Vector3.RIGHT, deg_to_rad(jitter_x))
		var line := CSGBox3D.new()
		line.name = "Line%d" % i
		line.size = Vector3(line_width, line_width, 0.1)
		line.material = _material
		line.transform = Transform3D(rot, Vector3.ZERO)
		line.position = -rot.z * 0.05
		add_child(line)
		_lines.append(line)

func _basis_from_forward(direction: Vector3) -> Basis:
	var up: Vector3 = Vector3.UP
	if absf(direction.dot(up)) > 0.95:
		up = Vector3.FORWARD
	var right: Vector3 = direction.cross(up).normalized()
	var new_up: Vector3 = right.cross(direction).normalized()
	return Basis(right, new_up, -direction)

func _process(delta: float) -> void:
	_elapsed += delta
	var alpha: float = 1.0
	for i in range(_lines.size()):
		var line: CSGBox3D = _lines[i] as CSGBox3D
		if line == null:
			continue
		var stretch_t: float = clampf(_elapsed / maxf(appear_duration, 0.001), 0.0, 1.0)
		var current_length: float = lerpf(0.05, line_length, ease(stretch_t, 0.3))
		line.size = Vector3(line_width, line_width, current_length)
		line.position = -line.transform.basis.z * (current_length * 0.5)
	if _elapsed > appear_duration:
		var fade_t: float = clampf((_elapsed - appear_duration) / maxf(fade_duration, 0.001), 0.0, 1.0)
		alpha = lerpf(1.0, 0.0, fade_t)
		if _material != null:
			var c: Color = _material.albedo_color
			c.a = color.a * alpha
			_material.albedo_color = c
		if _elapsed >= appear_duration + fade_duration:
			queue_free()
