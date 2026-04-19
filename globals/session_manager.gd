class_name SessionManager
extends Node

@export var death_reload_delay: float = 1.6
@export var death_flash_color: Color = Color(0.8, 0.05, 0.0, 0.7)

var _reloading: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameEvents.player_died.connect(_on_player_died)

func _unhandled_input(event: InputEvent) -> void:
	if _reloading:
		return
	if event.is_action_pressed("reload_scene"):
		_reload_now()

func _on_player_died() -> void:
	if _reloading:
		return
	_reloading = true
	var player: Player = _find_player()
	if player != null:
		player.invulnerable = true
		player.set_physics_process(false)
	var se: ScreenEffects = ScreenEffects.get_instance()
	if se != null:
		se.flash(death_flash_color, 0.6)
		se.set_vignette(0.6, Color(0.8, 0.05, 0.0, 1.0))
	var timer: SceneTreeTimer = get_tree().create_timer(death_reload_delay, true, false, true)
	await timer.timeout
	_reload_now()

func _reload_now() -> void:
	_reloading = true
	if absf(Engine.time_scale - 1.0) > 0.001:
		Engine.time_scale = 1.0
	get_tree().reload_current_scene.call_deferred()

func _find_player() -> Player:
	var nodes: Array = get_tree().get_nodes_in_group(&"player")
	if not nodes.is_empty() and nodes[0] is Player:
		return nodes[0] as Player
	var root: Node = get_tree().current_scene
	if root == null:
		return null
	return _search_player(root)

func _search_player(n: Node) -> Player:
	if n is Player:
		return n as Player
	for c in n.get_children():
		var found: Player = _search_player(c)
		if found != null:
			return found
	return null
