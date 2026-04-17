class_name Hurtbox
extends Area3D

signal hit_received(event: DamageEvent)

@export var owner_ref: Node = null

func _ready() -> void:
	monitoring = false
	monitorable = true

func take_hit(event: DamageEvent) -> void:
	hit_received.emit(event)
