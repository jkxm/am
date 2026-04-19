extends Node

static func make_subtree_mouse_pass_through(root: Node) -> void:
	if root is Control:
		(root as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in root.get_children():
		make_subtree_mouse_pass_through(child)

signal player_state_changed(state_name: String)
signal player_stamina_changed(current: float, maximum: float)
signal player_enhanced_changed(current: float, maximum: float)
signal player_armor_state_changed(is_up: bool)
signal player_armor_regen_changed(progress: float)
signal player_health_changed(current: float, maximum: float)
signal player_died
signal player_landed_hit(damage: float)
signal player_took_hit(damage: float, armored: bool)
signal player_hit_landed_at(point: Vector3, normal: Vector3, charge_level: int)
signal player_charge_level_changed(level: int, progress: float)
signal player_charge_released
signal player_slam_impact(point: Vector3, radius: float)
signal player_knockback_delivered(point: Vector3, direction: Vector3, effective_force: float, resisted: bool, charge_level: int)
