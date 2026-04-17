class_name Armor
extends Node

signal state_changed(is_up: bool)
signal regen_changed(progress: float)

@export var passive_regen_duration: float = 8.0
@export var combat_regen_duration: float = 4.0
@export var combat_boost_window: float = 2.5

var _is_up: bool = true
var _regen: float = 1.0
var _combat_boost_timer: float = 0.0

func _ready() -> void:
	state_changed.emit(_is_up)
	regen_changed.emit(_regen)

func _process(delta: float) -> void:
	if _is_up:
		return
	var duration: float = combat_regen_duration if _combat_boost_timer > 0.0 else passive_regen_duration
	_regen = minf(1.0, _regen + delta / maxf(duration, 0.001))
	regen_changed.emit(_regen)
	if _regen >= 1.0:
		_is_up = true
		state_changed.emit(true)
	if _combat_boost_timer > 0.0:
		_combat_boost_timer = maxf(0.0, _combat_boost_timer - delta)

func absorb_hit() -> bool:
	if not _is_up:
		return false
	_is_up = false
	_regen = 0.0
	state_changed.emit(false)
	regen_changed.emit(_regen)
	return true

func accelerate() -> void:
	_combat_boost_timer = combat_boost_window

func is_up() -> bool:
	return _is_up

func regen_ratio() -> float:
	return _regen
