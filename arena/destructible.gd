class_name Destructible
extends StaticBody3D

signal broken

@export var max_health: float = 120.0

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _hurtbox_collision: CollisionShape3D = $Hurtbox/CollisionShape3D

var _health: float = 0.0
var _broken: bool = false
var _material: StandardMaterial3D

func _ready() -> void:
	_health = max_health
	_hurtbox.owner_ref = self
	_hurtbox.hit_received.connect(_on_hit_received)
	var existing: Material = _mesh.get_surface_override_material(0)
	if existing is StandardMaterial3D:
		_material = existing as StandardMaterial3D
	else:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color(0.55, 0.4, 0.3, 1)
		_mesh.set_surface_override_material(0, _material)

func _on_hit_received(event: DamageEvent) -> void:
	if _broken:
		return
	_health = maxf(0.0, _health - event.amount)
	_update_color()
	if _health <= 0.0:
		_break()

func _update_color() -> void:
	var ratio: float = _health / maxf(max_health, 0.001)
	_material.albedo_color = Color(0.55, 0.4, 0.3, 1).lerp(Color(0.3, 0.15, 0.1, 1), 1.0 - ratio)

func _break() -> void:
	_broken = true
	_collision.disabled = true
	_hurtbox_collision.disabled = true
	_mesh.visible = false
	broken.emit()
