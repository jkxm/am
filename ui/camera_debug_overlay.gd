extends CanvasLayer

@export_node_path("Node3D") var camera_path: NodePath
@export_node_path("Node") var player_path: NodePath
@export_node_path("Node3D") var occlusion_fader_path: NodePath

@onready var _panel: PanelContainer = $Panel
@onready var _context_label: Label = $Panel/VBox/ContextLabel
@onready var _distance_label: Label = $Panel/VBox/DistanceLabel
@onready var _height_label: Label = $Panel/VBox/HeightLabel
@onready var _yaw_pitch_label: Label = $Panel/VBox/YawPitchLabel
@onready var _occluder_label: Label = $Panel/VBox/OccluderLabel
@onready var _wall_label: Label = $Panel/VBox/WallLabel
@onready var _move_raw_label: Label = $Panel/VBox/MoveRawLabel
@onready var _move_projected_label: Label = $Panel/VBox/MoveProjectedLabel
@onready var _velocity_label: Label = $Panel/VBox/VelocityLabel

var _camera: CombatCamera = null
var _player: Player = null
var _occlusion_fader: OcclusionFader = null

func _ready() -> void:
	GameEvents.make_subtree_mouse_pass_through(self)
	if camera_path != NodePath():
		_camera = get_node_or_null(camera_path) as CombatCamera
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as Player
	if occlusion_fader_path != NodePath():
		_occlusion_fader = get_node_or_null(occlusion_fader_path) as OcclusionFader
	_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("toggle_camera_debug") and event.is_action_pressed("toggle_camera_debug"):
		_panel.visible = not _panel.visible

func _process(_delta: float) -> void:
	if _camera == null or not _panel.visible:
		return
	_context_label.text = "Context: %s" % String(_camera.current_context())
	_distance_label.text = "Distance: %.2f" % _camera.effective_distance()
	_height_label.text = "Height: %.2f" % _camera.effective_height()
	var yaw_basis: Basis = _camera.get_yaw_basis()
	var pitch_basis: Basis = _camera.get_pitch_basis()
	var yaw_deg: float = rad_to_deg(atan2(yaw_basis.z.x, yaw_basis.z.z))
	var pitch_deg: float = rad_to_deg(asin(clampf(-pitch_basis.z.y, -1.0, 1.0)))
	_yaw_pitch_label.text = "Yaw: %6.1f°  Pitch: %6.1f°" % [yaw_deg, pitch_deg]
	var occ: int = 0
	if _occlusion_fader != null:
		occ = _occlusion_fader.occluder_count()
	_occluder_label.text = "Occluders: %d" % occ

	if _player == null:
		_wall_label.text = "Wall: —"
		_move_raw_label.text = "Move raw: —"
		_move_projected_label.text = "Move proj: —"
		_velocity_label.text = "Velocity: —"
		return

	if _player.wall_detector != null and _player.wall_detector.has_wall():
		var n: Vector3 = _player.wall_detector.wall_normal()
		_wall_label.text = "Wall normal: (%.2f, %.2f, %.2f)" % [n.x, n.y, n.z]
	else:
		_wall_label.text = "Wall: none"

	var move_input: Vector2 = _player.read_move_input()
	var cam_forward: Vector3 = _camera.get_camera_forward()
	var cam_right: Vector3 = _camera.get_camera_right()
	var raw: Vector3 = cam_right * move_input.x + cam_forward * move_input.y
	_move_raw_label.text = "Move raw: len=%.2f  (%.2f, %.2f, %.2f)" % [raw.length(), raw.x, raw.y, raw.z]
	if _player.wall_detector != null and _player.wall_detector.has_wall():
		var n: Vector3 = _player.wall_detector.wall_normal()
		var proj: Vector3 = raw - n * raw.dot(n)
		_move_projected_label.text = "Move proj: len=%.2f  (%.2f, %.2f, %.2f)" % [proj.length(), proj.x, proj.y, proj.z]
	else:
		_move_projected_label.text = "Move proj: (ground)"

	var v: Vector3 = _player.velocity
	_velocity_label.text = "Velocity: %.2f  (h=%.2f, v=%.2f)" % [v.length(), Vector2(v.x, v.z).length(), v.y]
