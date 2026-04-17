class_name Hitbox
extends Area3D

signal hit_landed(hurtbox: Hurtbox, event: DamageEvent)

@export var damage: float = 10.0
@export var stagger: bool = false
@export var hitstop_ms: float = 80.0
@export var screen_shake_amplitude: float = 0.3
@export var source: Node = null

var _active: bool = false
var _hit_this_swing: Array[Hurtbox] = []

func _ready() -> void:
	monitoring = false
	monitorable = false
	area_entered.connect(_on_area_entered)

func activate() -> void:
	_hit_this_swing.clear()
	_active = true
	monitoring = true

func deactivate() -> void:
	_active = false
	monitoring = false

func is_active() -> bool:
	return _active

func _on_area_entered(area: Area3D) -> void:
	if not _active:
		return
	if not (area is Hurtbox):
		return
	var hurtbox := area as Hurtbox
	if hurtbox in _hit_this_swing:
		return
	if hurtbox.owner_ref == source:
		return
	_hit_this_swing.append(hurtbox)

	var event := DamageEvent.new()
	event.amount = damage
	event.source = source
	event.stagger = stagger
	event.hitstop_ms = hitstop_ms
	event.screen_shake_amplitude = screen_shake_amplitude
	event.direction = (hurtbox.global_position - global_position).normalized()

	hurtbox.take_hit(event)
	hit_landed.emit(hurtbox, event)
