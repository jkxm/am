class_name MonsterState
extends Node

var monster: MonsterBrawler = null
var machine: MonsterStateMachine = null

func setup(_monster: MonsterBrawler, _machine: MonsterStateMachine) -> void:
	monster = _monster
	machine = _machine

func enter(_prev: String) -> void:
	pass

func exit(_next: String) -> void:
	pass

func physics_step(_delta: float) -> void:
	pass
