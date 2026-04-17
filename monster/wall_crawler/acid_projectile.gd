class_name AcidProjectile
extends Node3D

@export var speed: float = 12.0
@export var damage: float = 35.0
@export var gravity: float = 14.0
@export var max_lifetime: float = 4.0
@export var puddle_duration: float = 8.0
@export var puddle_radius: float = 2.0
@export var puddle_dps: float = 15.0

var velocity: Vector3 = Vector3.ZERO
var source: Node = null
var puddle_scene: PackedScene = null

@onready var _area: Area3D = $Area3D
var _lifetime: float = 0.0
var _done: bool = false

func launch(dir: Vector3, initial_speed: float, from_source: Node) -> void:
	velocity = dir.normalized() * initial_speed
	speed = initial_speed
	source = from_source

func _ready() -> void:
	_area.body_entered.connect(_on_body_entered)
	_area.area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if _done:
		return
	_lifetime += delta
	velocity.y -= gravity * delta
	global_position += velocity * delta
	if _lifetime >= max_lifetime:
		_detonate(global_position)

func _on_body_entered(body: Node) -> void:
	if _done:
		return
	if body == source:
		return
	if body.has_method("take_environmental_damage"):
		body.take_environmental_damage(damage)
	_detonate(global_position)

func _on_area_entered(area: Area3D) -> void:
	if _done:
		return
	if area is Hurtbox:
		var hb: Hurtbox = area as Hurtbox
		if hb.owner_ref == source:
			return
		var event := DamageEvent.new()
		event.amount = damage
		event.source = source
		event.direction = velocity.normalized()
		event.hitstop_ms = 40.0
		event.screen_shake_amplitude = 0.25
		hb.take_hit(event)
		_detonate(global_position)

func _detonate(at: Vector3) -> void:
	if _done:
		return
	_done = true
	_spawn_puddle(at)
	queue_free()

func _spawn_puddle(at: Vector3) -> void:
	if puddle_scene == null:
		return
	var puddle: AcidPuddle = puddle_scene.instantiate()
	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = get_parent()
	parent.add_child(puddle)
	var ground_y: float = at.y
	var ray_from: Vector3 = at + Vector3(0, 2.0, 0)
	var ray_to: Vector3 = at + Vector3(0, -20.0, 0)
	var ss: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1)
	var result: Dictionary = ss.intersect_ray(params)
	if not result.is_empty():
		ground_y = result.position.y + 0.01
	puddle.global_position = Vector3(at.x, ground_y, at.z)
	puddle.radius = puddle_radius
	puddle.lifetime = puddle_duration
	puddle.damage_per_second = puddle_dps
	puddle._apply_radius()
	AcidPuddle.register_spawn(puddle)
