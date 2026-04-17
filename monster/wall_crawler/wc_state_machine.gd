class_name WCStateMachine
extends Node

signal state_changed(new_state: String)

@export var initial_state: String = "Idle"

var _states: Dictionary = {}
var _current: WCState = null

func setup(monster: Node) -> void:
	for child: Node in get_children():
		if child is WCState:
			var state: WCState = child as WCState
			_states[state.name] = state
			state.setup(monster, self)
	if _states.has(initial_state):
		_current = _states[initial_state] as WCState
		_current.enter("")
		state_changed.emit(String(_current.name))

func current_name() -> String:
	return String(_current.name) if _current != null else ""

func change_to(state_name: String) -> void:
	if not _states.has(state_name):
		push_warning("Unknown wall crawler state: %s" % state_name)
		return
	var prev: String = String(_current.name) if _current != null else ""
	if _current != null:
		_current.exit(state_name)
	_current = _states[state_name] as WCState
	_current.enter(prev)
	state_changed.emit(state_name)

func physics_step(delta: float) -> void:
	if _current != null:
		_current.physics_step(delta)
