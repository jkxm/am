class_name TrajectoryPreview
extends Node3D

@export var dot_count: int = 12
@export var dot_spacing: float = 0.5
@export var dot_size: float = 0.08
@export var color_in_range: Color = Color(1.0, 1.0, 1.0, 0.8)
@export var color_out_of_range: Color = Color(1.0, 0.35, 0.35, 0.5)

var _dots: Array[MeshInstance3D] = []
var _materials: Array[StandardMaterial3D] = []

func _ready() -> void:
	top_level = true
	var mesh := SphereMesh.new()
	mesh.radius = dot_size
	mesh.height = dot_size * 2.0
	for i: int in range(dot_count):
		var dot := MeshInstance3D.new()
		dot.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_in_range
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = color_in_range
		dot.set_surface_override_material(0, mat)
		dot.visible = false
		add_child(dot)
		_dots.append(dot)
		_materials.append(mat)

func hide_preview() -> void:
	for dot: MeshInstance3D in _dots:
		dot.visible = false

func update_preview(origin: Vector3, direction: Vector3, launch_distance: float, launch_speed: float, active_duration: float, gravity_delay: float, gravity: float) -> void:
	if _dots.is_empty() or direction.length() < 0.01:
		hide_preview()
		return

	var total_distance: float = dot_count * dot_spacing
	var max_distance: float = launch_distance
	var active_distance: float = launch_distance
	var active_time: float = active_distance / maxf(launch_speed, 0.1)
	var gravity_onset: float = active_time + gravity_delay

	var dir: Vector3 = direction.normalized()

	for i: int in range(dot_count):
		var arc_distance: float = float(i + 1) * dot_spacing
		var t: float = arc_distance / maxf(launch_speed, 0.1)
		var in_range: bool = arc_distance <= max_distance
		var pos: Vector3 = origin + dir * minf(arc_distance, max_distance)
		if t > gravity_onset:
			var fall_time: float = t - gravity_onset
			pos.y -= 0.5 * gravity * fall_time * fall_time
		_dots[i].global_position = pos
		_dots[i].visible = true
		var col: Color = color_in_range if in_range else color_out_of_range
		_materials[i].albedo_color = col
		_materials[i].emission = col
