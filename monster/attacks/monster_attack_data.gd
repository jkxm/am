class_name MonsterAttackData
extends Resource

@export var label: String = "Attack"
@export var telegraph_time: float = 0.6
@export var active_time: float = 0.2
@export var recovery_time: float = 0.7
@export var damage: float = 20.0
@export var hitstop_ms: float = 80.0
@export var screen_shake_amplitude: float = 0.4
@export var min_range: float = 0.0
@export var max_range: float = 4.0
@export var cooldown: float = 2.5
@export var advance_distance: float = 1.0
@export var hitbox_offset: Vector3 = Vector3(0.0, 1.4, -2.0)
@export var hitbox_size: Vector3 = Vector3(3.0, 2.0, 3.5)
@export var telegraph_color: Color = Color(1, 0.7, 0.2, 1)
@export var requires_head: bool = false
@export var requires_tail: bool = false

func total_duration() -> float:
	return telegraph_time + active_time + recovery_time

func active_start() -> float:
	return telegraph_time

func active_end() -> float:
	return telegraph_time + active_time
