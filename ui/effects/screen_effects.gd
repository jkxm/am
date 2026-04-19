class_name ScreenEffects
extends CanvasLayer

@export var flash_decay_speed: float = 15.0
@export var vignette_lerp_speed: float = 8.0
@export var aberration_decay_speed: float = 10.0

var _flash_color: Color = Color(1, 1, 1, 0)
var _flash_alpha: float = 0.0
var _vignette_current: float = 0.0
var _vignette_target: float = 0.0
var _vignette_color: Color = Color.BLACK
var _aberration_current: float = 0.0
var _vignette_pulse_amp: float = 0.0
var _vignette_pulse_speed: float = 0.0
var _vignette_base: float = 0.0
var _vignette_pulse_time: float = 0.0

@onready var _rect: ColorRect = $EffectRect
@onready var _mat: ShaderMaterial = _rect.material as ShaderMaterial

static var _instance: ScreenEffects = null

static func get_instance() -> ScreenEffects:
	return _instance

func _ready() -> void:
	_instance = self
	layer = 100
	_update_shader()

func _exit_tree() -> void:
	if _instance == self:
		_instance = null

func flash(color: Color, duration: float = 0.15) -> void:
	_flash_color = color
	_flash_alpha = color.a
	if duration > 0.0:
		flash_decay_speed = 1.0 / duration
	_update_shader()

func set_vignette(intensity: float, color: Color) -> void:
	_vignette_target = intensity
	_vignette_color = color
	_vignette_pulse_amp = 0.0
	_update_shader()

func pulse_vignette(base: float, amplitude: float, speed: float, color: Color) -> void:
	_vignette_base = base
	_vignette_target = base
	_vignette_pulse_amp = amplitude
	_vignette_pulse_speed = speed
	_vignette_color = color

func clear_vignette() -> void:
	_vignette_target = 0.0
	_vignette_base = 0.0
	_vignette_pulse_amp = 0.0

func spike_aberration(amount: float) -> void:
	_aberration_current = maxf(_aberration_current, amount)

func _process(delta: float) -> void:
	var real_delta: float = delta
	if Engine.time_scale > 0.001:
		real_delta = delta / Engine.time_scale

	_flash_alpha = lerpf(_flash_alpha, 0.0, clampf(flash_decay_speed * real_delta, 0.0, 1.0))
	if _vignette_pulse_amp > 0.0:
		_vignette_pulse_time += real_delta * _vignette_pulse_speed
		_vignette_current = _vignette_base + sin(_vignette_pulse_time) * _vignette_pulse_amp
	else:
		_vignette_current = lerpf(_vignette_current, _vignette_target, clampf(vignette_lerp_speed * real_delta, 0.0, 1.0))
	_aberration_current = lerpf(_aberration_current, 0.0, clampf(aberration_decay_speed * real_delta, 0.0, 1.0))
	_update_shader()

func _update_shader() -> void:
	if _mat == null:
		return
	var flash: Color = Color(_flash_color.r, _flash_color.g, _flash_color.b, _flash_alpha)
	_mat.set_shader_parameter("flash_color", flash)
	_mat.set_shader_parameter("vignette_intensity", _vignette_current)
	_mat.set_shader_parameter("vignette_color", _vignette_color)
	_mat.set_shader_parameter("aberration_amount", _aberration_current)
