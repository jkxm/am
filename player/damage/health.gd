class_name Health
extends Node

signal changed(current: float, maximum: float)
signal died

@export var maximum: float = 100.0

var current: float = 0.0
var _dead: bool = false

func _ready() -> void:
	current = maximum
	changed.emit(current, maximum)

func damage(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	current = maxf(0.0, current - amount)
	changed.emit(current, maximum)
	if current <= 0.0 and not _dead:
		_dead = true
		died.emit()

func heal(amount: float) -> void:
	if _dead or amount <= 0.0:
		return
	current = minf(maximum, current + amount)
	changed.emit(current, maximum)

func revive() -> void:
	_dead = false
	current = maximum
	changed.emit(current, maximum)

func is_alive() -> bool:
	return not _dead

func ratio() -> float:
	return current / maxf(maximum, 0.001)
