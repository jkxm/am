class_name TargetDummy
extends StaticBody3D

@export var max_health: float = 300.0
@export var flash_duration: float = 0.12

@onready var _hurtbox: Hurtbox = $Hurtbox
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _health_bar: MeshInstance3D = $HealthBar

var _health: float = 0.0
var _flash_timer: float = 0.0
var _normal_material: StandardMaterial3D
var _flash_material: StandardMaterial3D

func _ready() -> void:
	_health = max_health
	_hurtbox.owner_ref = self
	_hurtbox.hit_received.connect(_on_hit_received)
	_normal_material = _mesh.get_surface_override_material(0) as StandardMaterial3D
	if _normal_material == null:
		_normal_material = StandardMaterial3D.new()
		_normal_material.albedo_color = Color(0.75, 0.3, 0.3, 1)
		_mesh.set_surface_override_material(0, _normal_material)
	_flash_material = StandardMaterial3D.new()
	_flash_material.albedo_color = Color(1, 1, 1, 1)
	_flash_material.emission_enabled = true
	_flash_material.emission = Color(1, 1, 1, 1)
	_update_health_bar()

func _process(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_mesh.set_surface_override_material(0, _normal_material)

func _on_hit_received(event: DamageEvent) -> void:
	_health = maxf(0.0, _health - event.amount)
	_flash_timer = flash_duration
	_mesh.set_surface_override_material(0, _flash_material)
	_update_health_bar()
	if _health <= 0.0:
		_reset()

func _update_health_bar() -> void:
	var ratio: float = _health / max_health
	_health_bar.scale.x = maxf(ratio, 0.01)

func _reset() -> void:
	_health = max_health
	_update_health_bar()
