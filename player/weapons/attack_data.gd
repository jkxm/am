class_name AttackData
extends Resource

@export var label: String = "Attack"
@export var charge_level: int = 0

# Timing
@export var windup_time: float = 0.25
@export var active_time: float = 0.12
@export var recovery_time: float = 0.4

# Cancel window: opens at active_end + cancel_window_start_frac * recovery_time
# and lasts cancel_window_duration seconds.
@export var has_cancel_window: bool = true
@export var cancel_window_start_frac: float = 0.6
@export var cancel_window_duration: float = 0.15

# Damage & resources
@export var damage: float = 30.0
@export var stamina_cost: float = 8.0
@export var enhanced_gain_on_hit: float = 12.0

# Feedback
@export var hitstop_ms: float = 40.0
@export var screen_shake_amplitude: float = 0.1

# Motion
@export var forward_motion: float = 1.0
@export var vertical_motion: float = 0.0
@export var launch_distance: float = 0.0
@export var launch_speed: float = 22.0
@export var slam_speed: float = 15.0
@export var impact_radius: float = 0.0

# Hitbox geometry (default primary swing hitbox)
@export var hitbox_offset: Vector3 = Vector3(0.0, 1.0, -1.5)
@export var hitbox_size: Vector3 = Vector3(2.0, 1.5, 3.0)

# Legacy combo chaining support (kept for combo systems that may return)
@export var can_be_chained: bool = false
@export var chains_to: int = -1

func total_duration() -> float:
	return windup_time + active_time + recovery_time

func active_start() -> float:
	return windup_time

func active_end() -> float:
	return windup_time + active_time

func cancel_start() -> float:
	return active_end() + cancel_window_start_frac * recovery_time

func cancel_end() -> float:
	return cancel_start() + cancel_window_duration
