class_name OcclusionFader
extends Node3D

@export var camera_path: NodePath
@export var player_path: NodePath
@export var detection_radius: float = 0.3
@export var target_dither: float = 0.85
@export var fade_in_speed: float = 8.0
@export var fade_out_speed: float = 4.0
@export var collision_mask: int = 1
@export var player_pivot_offset: float = 1.0

const DITHER_SHADER_PATH: String = "res://shaders/dither_fade.gdshader"

var _camera: Camera3D = null
var _player: Node3D = null
var _shape_cast: ShapeCast3D = null
var _dither_shader: Shader = null
var _occluding: Dictionary = {}

func _ready() -> void:
	_dither_shader = load(DITHER_SHADER_PATH) as Shader
	var cam_root: Node = null
	if camera_path != NodePath():
		cam_root = get_node_or_null(camera_path)
	if cam_root != null:
		for child in cam_root.find_children("", "Camera3D", true, false):
			_camera = child as Camera3D
			break
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as Node3D
	_setup_shape_cast()

func _setup_shape_cast() -> void:
	_shape_cast = ShapeCast3D.new()
	var shape := SphereShape3D.new()
	shape.radius = detection_radius
	_shape_cast.shape = shape
	_shape_cast.enabled = false
	_shape_cast.collide_with_bodies = true
	_shape_cast.collide_with_areas = false
	_shape_cast.collision_mask = collision_mask
	_shape_cast.max_results = 16
	add_child(_shape_cast)

func _physics_process(delta: float) -> void:
	if _camera == null or _player == null or _dither_shader == null:
		return

	var cam_pos: Vector3 = _camera.global_position
	var player_pos: Vector3 = _player.global_position + Vector3(0, player_pivot_offset, 0)
	var offset: Vector3 = player_pos - cam_pos

	var hits_this_frame: Dictionary = {}
	if offset.length() > 0.1:
		_shape_cast.global_position = cam_pos
		_shape_cast.target_position = offset
		_shape_cast.force_shapecast_update()
		for i: int in range(_shape_cast.get_collision_count()):
			var collider: Object = _shape_cast.get_collider(i)
			if collider == null:
				continue
			if not _is_valid_occluder(collider as Node):
				continue
			var mesh: MeshInstance3D = _find_mesh(collider as Node)
			if mesh == null:
				continue
			hits_this_frame[mesh] = true

	for mesh: MeshInstance3D in hits_this_frame:
		if not _occluding.has(mesh):
			_occluding[mesh] = {
				"amount": 0.0,
				"material": _ensure_dither_material(mesh),
			}
		var entry: Dictionary = _occluding[mesh]
		var material: ShaderMaterial = entry["material"]
		if material == null:
			continue
		var amount: float = lerpf(float(entry["amount"]), target_dither, clampf(fade_in_speed * delta, 0.0, 1.0))
		entry["amount"] = amount
		material.set_shader_parameter("dither_amount", amount)

	var to_remove: Array = []
	for mesh: MeshInstance3D in _occluding.keys():
		if hits_this_frame.has(mesh):
			continue
		var entry: Dictionary = _occluding[mesh]
		var material: ShaderMaterial = entry["material"]
		var amount: float = lerpf(float(entry["amount"]), 0.0, clampf(fade_out_speed * delta, 0.0, 1.0))
		entry["amount"] = amount
		if material != null:
			material.set_shader_parameter("dither_amount", amount)
		if amount < 0.01:
			if material != null:
				material.set_shader_parameter("dither_amount", 0.0)
			to_remove.append(mesh)

	for mesh: MeshInstance3D in to_remove:
		_occluding.erase(mesh)

func occluder_count() -> int:
	return _occluding.size()

func _is_valid_occluder(body: Node) -> bool:
	if body == null:
		return false
	if body == _player:
		return false
	if body.is_in_group(&"monsters"):
		return false
	return body is StaticBody3D

func _find_mesh(body: Node) -> MeshInstance3D:
	for child: Node in body.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
	return null

func _ensure_dither_material(mesh: MeshInstance3D) -> ShaderMaterial:
	var current: Material = mesh.get_surface_override_material(0)
	if current is ShaderMaterial:
		var existing: ShaderMaterial = current as ShaderMaterial
		if existing.shader == _dither_shader:
			return existing

	var albedo: Color = Color(0.5, 0.5, 0.5, 1)
	var rough: float = 0.8
	if current is StandardMaterial3D:
		var std: StandardMaterial3D = current as StandardMaterial3D
		albedo = std.albedo_color
		rough = std.roughness

	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = _dither_shader
	shader_mat.set_shader_parameter("albedo_color", albedo)
	shader_mat.set_shader_parameter("roughness", rough)
	shader_mat.set_shader_parameter("dither_amount", 0.0)
	mesh.set_surface_override_material(0, shader_mat)
	return shader_mat
