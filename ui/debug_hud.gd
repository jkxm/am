extends CanvasLayer

@export_node_path("Node") var player_path: NodePath
@export_node_path("Node") var monster_path: NodePath

@onready var _state_label: Label = $Panel/VBox/StateLabel
@onready var _stamina_label: Label = $Panel/VBox/StaminaLabel
@onready var _stamina_bar: ProgressBar = $Panel/VBox/StaminaBar
@onready var _enhanced_label: Label = $Panel/VBox/EnhancedLabel
@onready var _enhanced_bar: ProgressBar = $Panel/VBox/EnhancedBar
@onready var _armor_label: Label = $Panel/VBox/ArmorLabel
@onready var _armor_bar: ProgressBar = $Panel/VBox/ArmorBar
@onready var _health_label: Label = $Panel/VBox/HealthLabel
@onready var _health_bar: ProgressBar = $Panel/VBox/HealthBar
@onready var _velocity_label: Label = $Panel/VBox/VelocityLabel
@onready var _grounded_label: Label = $Panel/VBox/GroundedLabel
@onready var _wall_label: Label = $Panel/VBox/WallLabel
@onready var _iframe_label: Label = $Panel/VBox/IFrameLabel
@onready var _combat_label: Label = $Panel/VBox/CombatLabel
@onready var _monster_label: Label = $Panel/VBox/MonsterLabel
@onready var _diag_label: Label = $Panel/VBox/DiagLabel

var _player: Player = null
var _monster: MonsterBrawler = null

func _ready() -> void:
	GameEvents.make_subtree_mouse_pass_through(self)
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as Player
	if monster_path != NodePath():
		_monster = get_node_or_null(monster_path) as MonsterBrawler
	GameEvents.player_state_changed.connect(_on_state_changed)
	GameEvents.player_stamina_changed.connect(_on_stamina_changed)
	GameEvents.player_enhanced_changed.connect(_on_enhanced_changed)
	GameEvents.player_armor_state_changed.connect(_on_armor_state_changed)
	GameEvents.player_armor_regen_changed.connect(_on_armor_regen_changed)
	GameEvents.player_health_changed.connect(_on_health_changed)

func _process(_delta: float) -> void:
	if _player == null:
		return
	var v: Vector3 = _player.velocity
	_velocity_label.text = "Velocity: %5.2f  (h=%4.2f, v=%4.2f)" % [v.length(), Vector2(v.x, v.z).length(), v.y]
	_grounded_label.text = "Grounded: %s" % ("yes" if _player.is_on_floor() else "no")
	_iframe_label.text = "I-frames: %s%s" % [
		"ACTIVE" if _player.invulnerable else "off",
		"  (vulnerable)" if _player.is_vulnerable else ""
	]
	if _player.wall_detector != null and _player.wall_detector.has_wall():
		var n: Vector3 = _player.wall_detector.wall_normal()
		_wall_label.text = "Wall: yes  normal=(%.2f, %.2f, %.2f)" % [n.x, n.y, n.z]
	else:
		_wall_label.text = "Wall: no"

	_combat_label.text = _combat_text()
	_monster_label.text = _monster_text()
	_diag_label.text = _diag_text()

func _diag_text() -> String:
	if _player == null:
		return "Diag: —"
	var p: Vector3 = _player.global_position
	var slides: int = _player.get_slide_collision_count()
	var collider_name: String = "-"
	if slides > 0:
		var c: KinematicCollision3D = _player.get_slide_collision(0)
		if c != null and c.get_collider() != null:
			collider_name = c.get_collider().name
	return "Diag  ts=%.2f  pos=(%.1f, %.1f, %.1f)  slides=%d [%s]  invuln=%s  vuln=%s" % [
		Engine.time_scale, p.x, p.y, p.z,
		slides, collider_name,
		str(_player.invulnerable), str(_player.is_vulnerable)
	]

func _monster_text() -> String:
	if _monster == null:
		return "Monster: —"
	var hp_ratio: float = _monster.total_health / maxf(_monster.max_health, 0.001)
	var pieces: PackedStringArray = [
		"HP %3.0f%%" % (hp_ratio * 100.0),
		"Ph%d" % _monster.phase,
		_monster.current_state_name(),
	]
	if _monster.head_broken:
		pieces.append("head broken")
	if _monster.tail_broken:
		pieces.append("tail broken")
	return "Monster  " + "  ".join(pieces)

func _combat_text() -> String:
	if _player == null or _player.heavy_weapon == null:
		return "Combat: —"
	var state_name: String = _player.state_machine.current_name()
	var pieces: PackedStringArray = []
	if state_name == "ChargeAttack":
		var charge_state: Node = _player.state_machine.get_node_or_null("ChargeAttack")
		if charge_state != null and charge_state.has_method("charge_level") and charge_state.has_method("hold_time"):
			var level: int = int(charge_state.call("charge_level"))
			var hold: float = float(charge_state.call("hold_time"))
			var progress: float = _player.heavy_weapon.charge_progress(hold)
			pieces.append("Lv %d  %.0f%%  hold=%.2fs" % [level, progress * 100.0, hold])
	if _player.pending_attack != null:
		pieces.append("Pending: %s" % _player.pending_attack.label)
	if pieces.is_empty():
		return "Combat  %s" % state_name
	return "Combat  " + "  ".join(pieces)

func _on_state_changed(state_name: String) -> void:
	_state_label.text = "State: %s" % state_name

func _on_stamina_changed(current: float, maximum: float) -> void:
	_stamina_bar.max_value = maximum
	_stamina_bar.value = current
	_stamina_label.text = "Stamina: %4.1f / %4.1f" % [current, maximum]

func _on_enhanced_changed(current: float, maximum: float) -> void:
	_enhanced_bar.max_value = maximum
	_enhanced_bar.value = current
	_enhanced_label.text = "Enhanced: %4.1f / %4.1f" % [current, maximum]

func _on_armor_state_changed(is_up: bool) -> void:
	_armor_bar.modulate = Color(0.9, 0.85, 0.4, 1) if is_up else Color(0.85, 0.3, 0.3, 1)
	_refresh_armor_label()

func _on_armor_regen_changed(progress: float) -> void:
	_armor_bar.max_value = 1.0
	_armor_bar.value = progress
	_refresh_armor_label()

func _refresh_armor_label() -> void:
	if _player == null:
		return
	if _player.armor.is_up():
		_armor_label.text = "Armor: UP"
	else:
		_armor_label.text = "Armor: regen %3.0f%%" % (_player.armor.regen_ratio() * 100.0)

func _on_health_changed(current: float, maximum: float) -> void:
	_health_bar.max_value = maximum
	_health_bar.value = current
	_health_label.text = "Health: %4.1f / %4.1f" % [current, maximum]
