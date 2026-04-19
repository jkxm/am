class_name HitSparks
extends GPUParticles3D

@export var base_amount: int = 12
@export var base_speed: float = 6.0
@export var base_lifetime: float = 0.35

func configure(charge_level: int, direction: Vector3) -> void:
	amount = clampi(base_amount + charge_level * 6, 4, 64)
	lifetime = base_lifetime + 0.05 * charge_level
	one_shot = true
	emitting = true
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP, true)

func _ready() -> void:
	finished.connect(queue_free)
	one_shot = true
	explosiveness = 0.9
	if process_material == null:
		var m := ParticleProcessMaterial.new()
		m.direction = Vector3(0, 0, 1)
		m.spread = 35.0
		m.initial_velocity_min = base_speed * 0.6
		m.initial_velocity_max = base_speed * 1.2
		m.gravity = Vector3(0, -8, 0)
		m.scale_min = 0.05
		m.scale_max = 0.1
		m.color = Color(1.0, 0.85, 0.4)
		process_material = m
	if draw_pass_1 == null:
		var mesh := SphereMesh.new()
		mesh.radius = 0.03
		mesh.height = 0.06
		mesh.radial_segments = 6
		mesh.rings = 3
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.4)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.8, 0.3)
		mat.emission_energy_multiplier = 2.5
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh.material = mat
		draw_pass_1 = mesh
