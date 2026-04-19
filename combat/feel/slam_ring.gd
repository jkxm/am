class_name SlamRing
extends Node3D

@export var expand_speed: float = 10.0
@export var max_radius: float = 3.0
@export var lifetime: float = 0.45
@export var ring_color: Color = Color(1.0, 0.85, 0.4, 0.9)

var _elapsed: float = 0.0

@onready var _visual: CSGTorus3D = $Visual

func _ready() -> void:
	_apply_color()

func _apply_color() -> void:
	if _visual == null:
		return
	var mat: StandardMaterial3D = _visual.material as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = ring_color
		mat.emission_energy_multiplier = 1.5
		_visual.material = mat
	mat.albedo_color = ring_color

func _process(delta: float) -> void:
	_elapsed += delta
	var t: float = clampf(_elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	var radius: float = lerpf(0.2, max_radius, ease(t, 0.4))
	_visual.outer_radius = radius
	_visual.inner_radius = maxf(radius - 0.25, 0.05)
	var mat: StandardMaterial3D = _visual.material as StandardMaterial3D
	if mat != null:
		var c: Color = mat.albedo_color
		c.a = lerpf(ring_color.a, 0.0, t)
		mat.albedo_color = c
	if _elapsed >= lifetime:
		queue_free()
