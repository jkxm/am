class_name EnhancedResource
extends Node

signal changed(current: float, maximum: float)

@export var maximum: float = 100.0
@export var passive_regen_rate: float = 5.0
@export var hit_gain: float = 15.0

var current: float = maximum

func _ready() -> void:
	current = maximum
	changed.emit(current, maximum)

func _process(delta: float) -> void:
	if current < maximum:
		current = minf(maximum, current + passive_regen_rate * delta)
		changed.emit(current, maximum)

func try_spend(amount: float) -> bool:
	if current < amount:
		return false
	current -= amount
	changed.emit(current, maximum)
	return true

func has_for(amount: float) -> bool:
	return current >= amount

func gain_from_hit() -> void:
	current = minf(maximum, current + hit_gain)
	changed.emit(current, maximum)

func is_empty() -> bool:
	return current <= 0.0
