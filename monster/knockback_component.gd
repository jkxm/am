class_name KnockbackComponent
extends Node

signal knockback_applied(direction: Vector3, effective_force: float, resisted: bool)
signal knockback_landed
signal recovery_ended

@export_group("Force")
@export var base_force: float = 8.0
@export var min_threshold: float = 0.8
@export var charge_multiplier_l0: float = 0.0
@export var charge_multiplier_l1: float = 0.3
@export var charge_multiplier_l2: float = 0.6
@export var charge_multiplier_l3: float = 1.0

@export_group("Monster Resistance")
@export var base_resistance: float = 0.3

@export_group("Stacks")
@export var stack_decay_time: float = 5.0
@export var resistance_per_stack: float = 0.35
@export var max_stacks: int = 3

@export_group("Physics")
@export var drag: float = 5.0
@export var gravity: float = 20.0
@export var stop_speed: float = 0.8

@export_group("Recovery")
@export var recovery_duration: float = 0.6

@export_group("Feedback Thresholds")
@export var resisted_fraction: float = 0.7

var knockback_velocity: Vector3 = Vector3.ZERO
var stacks: int = 0
var stack_timer: float = 0.0
var recovery_timer: float = 0.0
var _travelling: bool = false
var _body: CharacterBody3D = null

func setup(body: CharacterBody3D) -> void:
	_body = body

func is_travelling() -> bool:
	return _travelling

func is_recovering() -> bool:
	return recovery_timer > 0.0 and not _travelling

func is_active() -> bool:
	return _travelling or recovery_timer > 0.0

func current_stack_reduction() -> float:
	return clampf(stacks * resistance_per_stack, 0.0, 0.95)

func compute_effective_force(raw_force: float) -> Dictionary:
	var after_resist: float = raw_force * (1.0 - clampf(base_resistance, 0.0, 1.0))
	var after_stacks: float = after_resist * (1.0 - current_stack_reduction())
	var resisted: bool = raw_force > 0.01 and (raw_force - after_stacks) / raw_force > resisted_fraction
	return {"effective": after_stacks, "resisted": resisted}

func force_for_charge_level(level: int) -> float:
	var mult: float = 0.0
	match level:
		0: mult = charge_multiplier_l0
		1: mult = charge_multiplier_l1
		2: mult = charge_multiplier_l2
		_: mult = charge_multiplier_l3
	return base_force * mult

func apply(direction: Vector3, raw_force: float) -> bool:
	if _body == null:
		return false
	if direction.length() < 0.001 or raw_force < 0.01:
		return false
	var result: Dictionary = compute_effective_force(raw_force)
	var effective: float = result["effective"]
	var resisted: bool = result["resisted"]
	if effective < min_threshold:
		knockback_applied.emit(direction.normalized(), effective, true)
		return false
	_add_stack()
	knockback_velocity = direction.normalized() * effective
	_travelling = true
	recovery_timer = 0.0
	knockback_applied.emit(direction.normalized(), effective, resisted)
	return true

func process(delta: float, body: CharacterBody3D) -> bool:
	if body != _body:
		_body = body
	_tick_stacks(delta)

	if _travelling:
		_tick_travel(delta)
		return true

	if recovery_timer > 0.0:
		recovery_timer = maxf(0.0, recovery_timer - delta)
		if recovery_timer <= 0.0:
			recovery_ended.emit()
		return false

	return false

func _tick_stacks(delta: float) -> void:
	if stacks <= 0:
		return
	stack_timer -= delta
	if stack_timer <= 0.0:
		stacks = maxi(0, stacks - 1)
		stack_timer = stack_decay_time

func _tick_travel(delta: float) -> void:
	if _body == null:
		return
	if _body.is_on_floor():
		if knockback_velocity.y < 0.0:
			knockback_velocity.y = 0.0
	else:
		knockback_velocity.y -= gravity * delta
	var horiz: Vector3 = Vector3(knockback_velocity.x, 0.0, knockback_velocity.z)
	horiz = horiz.move_toward(Vector3.ZERO, drag * delta)
	knockback_velocity.x = horiz.x
	knockback_velocity.z = horiz.z
	_body.velocity = knockback_velocity
	_body.move_and_slide()
	var grounded: bool = _body.is_on_floor()
	var planar_speed: float = Vector2(knockback_velocity.x, knockback_velocity.z).length()
	if grounded and planar_speed < stop_speed:
		knockback_velocity = Vector3.ZERO
		_body.velocity = Vector3.ZERO
		_travelling = false
		recovery_timer = recovery_duration
		knockback_landed.emit()

func _add_stack() -> void:
	stacks = mini(stacks + 1, max_stacks)
	stack_timer = stack_decay_time

func reset() -> void:
	knockback_velocity = Vector3.ZERO
	stacks = 0
	stack_timer = 0.0
	recovery_timer = 0.0
	_travelling = false
