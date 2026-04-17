extends CanvasLayer

@export var max_entries: int = 18
@export var font_color: Color = Color(0.9, 1.0, 0.9, 1.0)

@onready var _vbox: VBoxContainer = $Panel/VBox

var _start_ms: int = 0

func _ready() -> void:
	GameEvents.make_subtree_mouse_pass_through(self)
	_start_ms = Time.get_ticks_msec()
	GameEvents.player_state_changed.connect(_on_state_changed)
	append("boot")

func _on_state_changed(state_name: String) -> void:
	append("→ " + state_name)

func append(text: String) -> void:
	if _vbox == null:
		return
	var label := Label.new()
	label.text = "%6.2fs  %s" % [_elapsed(), text]
	label.add_theme_color_override("font_color", font_color)
	_vbox.add_child(label)
	_vbox.move_child(label, 0)
	while _vbox.get_child_count() > max_entries:
		var last: Node = _vbox.get_child(_vbox.get_child_count() - 1)
		_vbox.remove_child(last)
		last.queue_free()

func _elapsed() -> float:
	return (Time.get_ticks_msec() - _start_ms) / 1000.0
