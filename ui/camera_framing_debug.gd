extends CanvasLayer

@export_node_path("Node3D") var camera_path: NodePath
@export_node_path("Node") var player_path: NodePath

@export var pitch_step_deg: float = 1.0
@export var offset_step: float = 0.1
@export var vertical_step: float = 0.1
@export var fov_step: float = 1.0

@onready var _root: Control = $Root
@onready var _values_label: Label = $Root/Values
@onready var _guides: Control = $Root/Guides
@onready var _player_dot: ColorRect = $Root/Guides/PlayerDot

var _camera_root: CombatCamera = null
var _camera3d: Camera3D = null
var _player: Node3D = null
var _tuning_context: StringName = &"ground"
var _visible: bool = false

const CONTEXTS: Array[StringName] = [&"ground", &"wall", &"air", &"wall_charge"]

func _ready() -> void:
	GameEvents.make_subtree_mouse_pass_through(self)
	if camera_path != NodePath():
		_camera_root = get_node_or_null(camera_path) as CombatCamera
		if _camera_root != null:
			for child in _camera_root.find_children("", "Camera3D", true, false):
				_camera3d = child as Camera3D
				break
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as Node3D
	_root.visible = false
	_guides.draw.connect(_draw_guides)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F4:
			_visible = not _visible
			_root.visible = _visible
			return
	if not _visible:
		return
	if not (event is InputEventKey and event.pressed):
		return
	var key: int = (event as InputEventKey).keycode
	match key:
		KEY_1: _tuning_context = &"ground"
		KEY_2: _tuning_context = &"wall"
		KEY_3: _tuning_context = &"air"
		KEY_4: _tuning_context = &"wall_charge"
		KEY_UP:
			_adjust_pitch(pitch_step_deg)
		KEY_DOWN:
			_adjust_pitch(-pitch_step_deg)
		KEY_LEFT:
			_adjust_horizontal(-offset_step)
		KEY_RIGHT:
			_adjust_horizontal(offset_step)
		KEY_PAGEUP:
			_adjust_vertical(vertical_step)
		KEY_PAGEDOWN:
			_adjust_vertical(-vertical_step)
		KEY_HOME:
			_adjust_fov(fov_step)
		KEY_END:
			_adjust_fov(-fov_step)
		KEY_P:
			_print_current()

func _process(_delta: float) -> void:
	if not _visible:
		return
	if _camera_root == null:
		return
	_update_label()
	_update_player_dot()
	_guides.queue_redraw()

func _update_label() -> void:
	var active: StringName = _camera_root.current_context()
	var text: String = "[F4] Framing Debug — tuning: %s (active: %s)\n" % [String(_tuning_context), String(active)]
	text += "Pitch: ground=%.1f° wall=%.1f° air=%.1f° wall_charge=%.1f°\n" % [
		_camera_root.ground_pitch_bias, _camera_root.wall_pitch_bias,
		_camera_root.air_pitch_bias, _camera_root.wall_charge_pitch_bias
	]
	text += "H Offset: ground=%.2f wall=%.2f air=%.2f wall_charge=%.2f\n" % [
		_camera_root.ground_offset, _camera_root.wall_offset,
		_camera_root.air_offset, _camera_root.wall_charge_offset
	]
	text += "V Offset: ground=%.2f wall=%.2f air=%.2f wall_charge=%.2f\n" % [
		_camera_root.ground_vertical_offset, _camera_root.wall_vertical_offset,
		_camera_root.air_vertical_offset, _camera_root.wall_charge_vertical_offset
	]
	text += "FOV:      ground=%.1f wall=%.1f air=%.1f wall_charge=%.1f\n" % [
		_camera_root.ground_fov, _camera_root.wall_fov,
		_camera_root.air_fov, _camera_root.wall_charge_fov
	]
	text += "\n"
	text += "Eff: pitch=%.1f°  h=%.2f  v=%.2f  fov=%.1f  dist=%.2f\n" % [
		_camera_root.effective_pitch_bias(), _camera_root.effective_horizontal_offset(),
		_camera_root.effective_vertical_offset(), _camera_root.effective_fov(),
		_camera_root.effective_distance()
	]
	text += "\n"
	text += "[1/2/3/4] ground/wall/air/wall_charge  [↑↓] pitch  [←→] h-offset\n"
	text += "[PgUp/PgDn] v-offset  [Home/End] FOV  [P] print to console"
	_values_label.text = text

func _update_player_dot() -> void:
	if _camera3d == null or _player == null:
		_player_dot.visible = false
		return
	var pos3d: Vector3 = _player.global_position + Vector3(0, 1.0, 0)
	if _camera3d.is_position_behind(pos3d):
		_player_dot.visible = false
		return
	var screen: Vector2 = _camera3d.unproject_position(pos3d)
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	if screen.x < 0 or screen.x > viewport.x or screen.y < 0 or screen.y > viewport.y:
		_player_dot.visible = false
		return
	_player_dot.visible = true
	_player_dot.position = screen - _player_dot.size * 0.5

func _draw_guides() -> void:
	if not _visible:
		return
	var viewport: Vector2 = _guides.size
	var thirds_color: Color = Color(1, 1, 1, 0.2)
	var center_color: Color = Color(1, 1, 1, 0.35)
	_guides.draw_line(Vector2(viewport.x / 3.0, 0), Vector2(viewport.x / 3.0, viewport.y), thirds_color, 1.0)
	_guides.draw_line(Vector2(viewport.x * 2.0 / 3.0, 0), Vector2(viewport.x * 2.0 / 3.0, viewport.y), thirds_color, 1.0)
	_guides.draw_line(Vector2(0, viewport.y / 3.0), Vector2(viewport.x, viewport.y / 3.0), thirds_color, 1.0)
	_guides.draw_line(Vector2(0, viewport.y * 2.0 / 3.0), Vector2(viewport.x, viewport.y * 2.0 / 3.0), thirds_color, 1.0)
	var c: Vector2 = viewport * 0.5
	_guides.draw_line(Vector2(c.x - 10, c.y), Vector2(c.x + 10, c.y), center_color, 1.5)
	_guides.draw_line(Vector2(c.x, c.y - 10), Vector2(c.x, c.y + 10), center_color, 1.5)

func _adjust_pitch(delta_deg: float) -> void:
	match _tuning_context:
		&"ground": _camera_root.set_ground_pitch_bias(_camera_root.ground_pitch_bias + delta_deg)
		&"wall": _camera_root.set_wall_pitch_bias(_camera_root.wall_pitch_bias + delta_deg)
		&"air": _camera_root.set_air_pitch_bias(_camera_root.air_pitch_bias + delta_deg)
		&"wall_charge": _camera_root.set_wall_charge_pitch_bias(_camera_root.wall_charge_pitch_bias + delta_deg)

func _adjust_horizontal(delta_offset: float) -> void:
	match _tuning_context:
		&"ground": _camera_root.set_ground_offset(_camera_root.ground_offset + delta_offset)
		&"wall": _camera_root.set_wall_offset(_camera_root.wall_offset + delta_offset)
		&"air": _camera_root.set_air_offset(_camera_root.air_offset + delta_offset)
		&"wall_charge": _camera_root.set_wall_charge_offset(_camera_root.wall_charge_offset + delta_offset)

func _adjust_vertical(delta_offset: float) -> void:
	match _tuning_context:
		&"ground": _camera_root.set_ground_vertical_offset(_camera_root.ground_vertical_offset + delta_offset)
		&"wall": _camera_root.set_wall_vertical_offset(_camera_root.wall_vertical_offset + delta_offset)
		&"air": _camera_root.set_air_vertical_offset(_camera_root.air_vertical_offset + delta_offset)
		&"wall_charge": _camera_root.set_wall_charge_vertical_offset(_camera_root.wall_charge_vertical_offset + delta_offset)

func _adjust_fov(delta_fov: float) -> void:
	match _tuning_context:
		&"ground": _camera_root.set_ground_fov(_camera_root.ground_fov + delta_fov)
		&"wall": _camera_root.set_wall_fov(_camera_root.wall_fov + delta_fov)
		&"air": _camera_root.set_air_fov(_camera_root.air_fov + delta_fov)
		&"wall_charge": _camera_root.set_wall_charge_fov(_camera_root.wall_charge_fov + delta_fov)

func _print_current() -> void:
	print("-- Camera framing values --")
	print("ground_pitch_bias = %.1f" % _camera_root.ground_pitch_bias)
	print("wall_pitch_bias = %.1f" % _camera_root.wall_pitch_bias)
	print("air_pitch_bias = %.1f" % _camera_root.air_pitch_bias)
	print("wall_charge_pitch_bias = %.1f" % _camera_root.wall_charge_pitch_bias)
	print("ground_offset = %.2f" % _camera_root.ground_offset)
	print("wall_offset = %.2f" % _camera_root.wall_offset)
	print("air_offset = %.2f" % _camera_root.air_offset)
	print("wall_charge_offset = %.2f" % _camera_root.wall_charge_offset)
	print("ground_vertical_offset = %.2f" % _camera_root.ground_vertical_offset)
	print("wall_vertical_offset = %.2f" % _camera_root.wall_vertical_offset)
	print("air_vertical_offset = %.2f" % _camera_root.air_vertical_offset)
	print("wall_charge_vertical_offset = %.2f" % _camera_root.wall_charge_vertical_offset)
	print("ground_fov = %.1f" % _camera_root.ground_fov)
	print("wall_fov = %.1f" % _camera_root.wall_fov)
	print("air_fov = %.1f" % _camera_root.air_fov)
	print("wall_charge_fov = %.1f" % _camera_root.wall_charge_fov)
