class_name WCAttackData
extends Resource

enum Kind { MELEE, PROJECTILE, DIVE, CHARGE, BARRAGE }
enum Surface { GROUND, WALL, EITHER }

@export var label: String = "Attack"
@export var kind: int = Kind.MELEE
@export var surface: int = Surface.EITHER

@export var telegraph_time: float = 0.5
@export var active_time: float = 0.2
@export var recovery_time: float = 0.5
@export var damage: float = 20.0
@export var hitstop_ms: float = 80.0
@export var screen_shake_amplitude: float = 0.4
@export var cooldown: float = 2.5

@export var min_range: float = 0.0
@export var max_range: float = 5.0

@export var hitbox_offset: Vector3 = Vector3(0.0, 0.0, -2.0)
@export var hitbox_size: Vector3 = Vector3(2.0, 1.5, 2.5)

@export var advance_distance: float = 0.0
@export var advance_speed: float = 0.0

@export var projectile_speed: float = 12.0
@export var projectile_damage: float = 35.0
@export var projectile_spawn_offset: Vector3 = Vector3(0.0, 1.0, -1.5)
@export var projectile_puddle_duration: float = 8.0
@export var projectile_puddle_radius: float = 2.0
@export var barrage_count: int = 1
@export var barrage_delay: float = 0.3
@export var barrage_spread_deg: float = 0.0

@export var dive_speed: float = 18.0
@export var dive_shockwave_radius: float = 3.0
@export var dive_shockwave_damage: float = 20.0

@export var telegraph_color: Color = Color(1, 0.45, 0.2, 1)

@export var requires_head: bool = false
@export var requires_rear_legs: bool = false
@export var exposes_throat: bool = false
@export var exposes_belly_on_recovery: bool = false

func total_duration() -> float:
	return telegraph_time + active_time + recovery_time

func active_start() -> float:
	return telegraph_time

func active_end() -> float:
	return telegraph_time + active_time
