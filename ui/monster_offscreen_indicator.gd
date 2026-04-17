extends CanvasLayer

@export var camera_path: NodePath
@export var edge_margin: float = 50.0
@export var monster_group: StringName = &"monsters"
@export var indicator_attack_pulse_speed: float = 4.0

@onready var _arrow: Label = $Arrow

var _camera_root: CombatCamera = null
var _camera3d: Camera3D = null
var _pulse_phase: float = 0.0

func _ready() -> void:
	GameEvents.make_subtree_mouse_pass_through(self)
	if camera_path != NodePath():
		_camera_root = get_node_or_null(camera_path) as CombatCamera
		if _camera_root != null:
			for child in _camera_root.find_children("", "Camera3D", true, false):
				_camera3d = child as Camera3D
				break
	_arrow.visible = false

func _process(delta: float) -> void:
	if _camera3d == null:
		_arrow.visible = false
		return

	var monster: Node3D = _find_monster()
	if monster == null:
		_arrow.visible = false
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var center: Vector2 = viewport_size * 0.5
	var target_pos: Vector3 = monster.global_position + Vector3(0, 1.5, 0)
	var behind: bool = _camera3d.is_position_behind(target_pos)
	var screen: Vector2 = _camera3d.unproject_position(target_pos)

	var onscreen: bool = not behind and screen.x >= 0 and screen.x <= viewport_size.x and screen.y >= 0 and screen.y <= viewport_size.y
	if onscreen:
		_arrow.visible = false
		return

	var direction: Vector2 = screen - center
	if behind:
		direction = -direction
	if direction.length() < 0.01:
		_arrow.visible = false
		return
	direction = direction.normalized()

	var half_w: float = viewport_size.x * 0.5 - edge_margin
	var half_h: float = viewport_size.y * 0.5 - edge_margin
	var scale_x: float = half_w / absf(direction.x) if absf(direction.x) > 0.0001 else INF
	var scale_y: float = half_h / absf(direction.y) if absf(direction.y) > 0.0001 else INF
	var edge_scale: float = minf(scale_x, scale_y)
	var edge_point: Vector2 = center + direction * edge_scale

	_arrow.visible = true
	_arrow.position = edge_point - Vector2(30, 30)
	_arrow.rotation = atan2(direction.y, direction.x) - PI * 0.5

	var attacking: bool = _is_attacking(monster)
	if attacking:
		_pulse_phase += delta * indicator_attack_pulse_speed
		var pulse: float = 0.6 + 0.4 * (0.5 + 0.5 * sin(_pulse_phase * TAU))
		_arrow.modulate = Color(1, 0.25, 0.25, pulse)
	else:
		_arrow.modulate = Color(1, 0.55, 0.55, 0.85)

func _find_monster() -> Node3D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var nodes: Array = tree.get_nodes_in_group(monster_group)
	for node: Node in nodes:
		if node is Node3D:
			return node as Node3D
	return null

func _is_attacking(monster: Node3D) -> bool:
	if monster.has_method("current_state_name"):
		return String(monster.call("current_state_name")) == "Attack"
	return false
