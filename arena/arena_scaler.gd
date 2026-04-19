class_name ArenaScaler
extends Node3D

@export var wall_scale: Vector3 = Vector3(1.0, 1.5, 1.5)
@export var wall_nodes: Array[NodePath] = [
	NodePath("WallRunLeft"),
	NodePath("WallRunRight"),
	NodePath("WallPerchApproach"),
	NodePath("Pillar"),
	NodePath("CorridorLeft"),
	NodePath("CorridorRight"),
]
@export var preserve_base_y: bool = true

func _ready() -> void:
	_apply_scale()

func _apply_scale() -> void:
	if wall_scale.is_equal_approx(Vector3.ONE):
		return
	for p in wall_nodes:
		var n: Node = get_node_or_null(p)
		if n == null or not (n is Node3D):
			continue
		_scale_wall(n as Node3D)

func _scale_wall(wall: Node3D) -> void:
	var base_y: float = wall.global_position.y
	var original_bottom: float = base_y
	if preserve_base_y:
		var half_extents: Vector3 = _collect_half_extents(wall)
		original_bottom = base_y - half_extents.y
	for child in wall.get_children():
		if child is CollisionShape3D:
			var cs: CollisionShape3D = child as CollisionShape3D
			if cs.shape is BoxShape3D:
				var b: BoxShape3D = (cs.shape as BoxShape3D).duplicate()
				b.size = b.size * wall_scale
				cs.shape = b
		elif child is MeshInstance3D:
			var mi: MeshInstance3D = child as MeshInstance3D
			if mi.mesh is BoxMesh:
				var m: BoxMesh = (mi.mesh as BoxMesh).duplicate()
				m.size = m.size * wall_scale
				mi.mesh = m
	if preserve_base_y:
		var new_half: Vector3 = _collect_half_extents(wall)
		wall.global_position.y = original_bottom + new_half.y

func _collect_half_extents(wall: Node3D) -> Vector3:
	for child in wall.get_children():
		if child is CollisionShape3D:
			var cs: CollisionShape3D = child as CollisionShape3D
			if cs.shape is BoxShape3D:
				return (cs.shape as BoxShape3D).size * 0.5
		elif child is MeshInstance3D:
			var mi: MeshInstance3D = child as MeshInstance3D
			if mi.mesh is BoxMesh:
				return (mi.mesh as BoxMesh).size * 0.5
	return Vector3.ZERO
