class_name WCState
extends Node

var monster: Node = null
var machine: Node = null

func setup(_monster: Node, _machine: Node) -> void:
	monster = _monster
	machine = _machine

func enter(_prev: String) -> void:
	pass

func exit(_next: String) -> void:
	pass

func physics_step(_delta: float) -> void:
	pass
