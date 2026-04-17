class_name AcidPuddle
extends Node3D

const MAX_ACTIVE: int = 5

static var _active: Array = []

static func register_spawn(puddle: AcidPuddle) -> void:
	_active = _active.filter(func(p: AcidPuddle) -> bool: return p != null and is_instance_valid(p))
	_active.append(puddle)
	while _active.size() > MAX_ACTIVE:
		var oldest: AcidPuddle = _active.pop_front() as AcidPuddle
		if oldest != null and is_instance_valid(oldest):
			oldest.queue_free()

@export var damage_per_second: float = 15.0
@export var radius: float = 2.0
@export var lifetime: float = 8.0
@export var tick_interval: float = 0.5

var _elapsed: float = 0.0
var _tick_timer: float = 0.0
var _bodies_in: Array[Node3D] = []

@onready var _area: Area3D = $Area3D
@onready var _shape: CollisionShape3D = $Area3D/CollisionShape3D
@onready var _visual: CSGCylinder3D = $Visual

func _ready() -> void:
	add_to_group(&"acid_puddles")
	_area.body_entered.connect(_on_body_entered)
	_area.body_exited.connect(_on_body_exited)
	_apply_radius()

func _apply_radius() -> void:
	var cyl: CylinderShape3D = _shape.shape as CylinderShape3D
	if cyl != null:
		cyl.radius = radius
		cyl.height = 0.4
	if _visual != null:
		_visual.radius = radius
		_visual.height = 0.1

func _process(delta: float) -> void:
	_elapsed += delta
	_tick_timer += delta
	if _tick_timer >= tick_interval:
		_tick_timer = 0.0
		_apply_damage_to_bodies()
	if _elapsed >= lifetime:
		queue_free()
		return
	var fade_start: float = lifetime - 1.5
	if _elapsed > fade_start:
		var t: float = clampf((_elapsed - fade_start) / 1.5, 0.0, 1.0)
		var m: StandardMaterial3D = _visual.material_override as StandardMaterial3D
		if m != null:
			var c: Color = m.albedo_color
			c.a = lerpf(0.6, 0.0, t)
			m.albedo_color = c

func _apply_damage_to_bodies() -> void:
	var tick_damage: float = damage_per_second * tick_interval
	for body: Node3D in _bodies_in:
		if body == null or not is_instance_valid(body):
			continue
		if not body.has_method("take_environmental_damage"):
			continue
		body.take_environmental_damage(tick_damage)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("take_environmental_damage") and not body in _bodies_in:
		_bodies_in.append(body)

func _on_body_exited(body: Node3D) -> void:
	_bodies_in.erase(body)
