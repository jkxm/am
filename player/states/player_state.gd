class_name PlayerState
extends Node

var player: Player = null
var machine: PlayerStateMachine = null

func setup(_player: Player, _machine: PlayerStateMachine) -> void:
	player = _player
	machine = _machine

func enter(_prev_state: String) -> void:
	pass

func exit(_next_state: String) -> void:
	pass

func physics_step(_delta: float) -> void:
	pass

func get_state_name() -> String:
	return name
