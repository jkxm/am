class_name WallDetector
extends Node3D

@export var ray_length: float = 0.7
@export var max_wall_angle_deg: float = 30.0

const DIRECTIONS: Array[Vector3] = [
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.LEFT,
	Vector3.RIGHT,
]

var _rays: Array[RayCast3D] = []
var _has_wall: bool = false
var _wall_normal: Vector3 = Vector3.ZERO
var _wall_point: Vector3 = Vector3.ZERO

func _ready() -> void:
	var owner_body: CollisionObject3D = _find_owner_body()
	for direction: Vector3 in DIRECTIONS:
		var ray := RayCast3D.new()
		ray.enabled = true
		ray.target_position = direction * ray_length
		ray.collide_with_bodies = true
		if owner_body != null:
			ray.add_exception(owner_body)
		add_child(ray)
		_rays.append(ray)

func _find_owner_body() -> CollisionObject3D:
	var node: Node = get_parent()
	while node != null:
		if node is CollisionObject3D:
			return node as CollisionObject3D
		node = node.get_parent()
	return null

func update() -> void:
	_has_wall = false
	var best_distance: float = INF
	var horizontal_threshold: float = cos(deg_to_rad(max_wall_angle_deg))
	for ray: RayCast3D in _rays:
		ray.force_raycast_update()
		if not ray.is_colliding():
			continue
		var normal: Vector3 = ray.get_collision_normal()
		var horizontal_amount: float = Vector2(normal.x, normal.z).length()
		if horizontal_amount < horizontal_threshold:
			continue
		var point: Vector3 = ray.get_collision_point()
		var distance: float = ray.global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			_has_wall = true
			_wall_normal = Vector3(normal.x, 0.0, normal.z).normalized()
			_wall_point = point

func has_wall() -> bool:
	return _has_wall

func wall_normal() -> Vector3:
	return _wall_normal

func wall_point() -> Vector3:
	return _wall_point

func wall_tangent_for(input_direction: Vector3) -> Vector3:
	if not _has_wall:
		return Vector3.ZERO
	var flat_input := Vector3(input_direction.x, 0.0, input_direction.z)
	var along := flat_input - _wall_normal * flat_input.dot(_wall_normal)
	return along.normalized() if along.length() > 0.01 else Vector3.ZERO

func project_onto_wall(direction: Vector3) -> Vector3:
	if not _has_wall:
		return Vector3.ZERO
	var along := direction - _wall_normal * direction.dot(_wall_normal)
	return along
