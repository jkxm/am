class_name Stamina
extends Node

signal changed(current: float, maximum: float)
signal emptied
signal refilled

@export var maximum: float = 100.0
@export var drain_rate: float = 25.0
@export var regen_rate: float = 20.0
@export var regen_delay: float = 0.6

var current: float = maximum
var _regen_timer: float = 0.0
var _was_empty: bool = false

func _ready() -> void:
	current = maximum
	changed.emit(current, maximum)

func _process(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return
	if current < maximum:
		current = minf(maximum, current + regen_rate * delta)
		changed.emit(current, maximum)
		if _was_empty and current >= maximum * 0.2:
			_was_empty = false
			refilled.emit()

func try_spend(amount: float) -> bool:
	if current < amount:
		return false
	current -= amount
	_regen_timer = regen_delay
	changed.emit(current, maximum)
	if current <= 0.0 and not _was_empty:
		_was_empty = true
		emptied.emit()
	return true

func drain(delta: float) -> bool:
	return drain_amount(drain_rate * delta)

func drain_amount(amount: float) -> bool:
	if current <= 0.0:
		return false
	current = maxf(0.0, current - amount)
	_regen_timer = regen_delay
	changed.emit(current, maximum)
	if current <= 0.0 and not _was_empty:
		_was_empty = true
		emptied.emit()
		return false
	return true

func is_empty() -> bool:
	return current <= 0.0
