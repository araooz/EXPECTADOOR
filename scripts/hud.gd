class_name Hud
extends CanvasLayer
## Capa mínima de interfaz, sin texto: el velo del cruce
## (el resplandor crece ante la puerta y, al cruzarla, todo queda blanco) y la
## huella: la postimagen de la puerta que aparece después en el blanco, sigue a
## la mirada y se deshace hasta desaparecer.

## Duración del paso al blanco total al cruzar.
@export var crossing_white_duration: float = 0.4

@export_group("Huella")
## Oscurecimiento máximo de la huella sobre el blanco (0,035 = 3,5 % de contraste).
@export var trace_peak_darkness: float = 0.035

var is_trace_finished: bool = false

var _crossed: bool = false

@onready var _veil: ColorRect = $Veil
@onready var _trace: ColorRect = $Trace
@onready var _trace_material: ShaderMaterial = _trace.material


func _ready() -> void:
	_veil.color = Color(1, 1, 1, 0)


## Resplandor previo al cruce (0 = nada, 1 = pantalla blanca).
func set_glare(amount: float) -> void:
	if _crossed:
		return
	_veil.color.a = clampf(amount, 0.0, 1.0)


## Al cruzar: todo queda blanco, y así permanece.
func play_crossing() -> void:
	if _crossed:
		return
	_crossed = true
	create_tween().tween_property(_veil, "color", Color(1, 1, 1, 1), crossing_white_duration)


## La huella de la puerta: aparece en el blanco ([param fade_in] s), se mantiene
## ([param hold] s), pierde su forma y desaparece ([param dissolve] s). Ocurre una
## sola vez. Sus tiempos son los mismos que los del eco ausente.
func play_trace(fade_in: float, hold: float, dissolve: float) -> void:
	if not _crossed or _trace.visible or is_trace_finished:
		return
	_set_trace_shape(1.0)
	_set_trace_darkness(0.0)
	_trace.show()
	var tween := create_tween()
	tween.tween_method(_set_trace_darkness, 0.0, trace_peak_darkness, fade_in) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(hold)
	tween.tween_method(_set_trace_shape, 1.0, 0.0, dissolve) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Se apaga durante el último 60 % de la disolución, mientras se hace mancha.
	tween.parallel().tween_method(_set_trace_darkness, trace_peak_darkness, 0.0, dissolve * 0.6) \
			.set_delay(dissolve * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		_trace.hide()
		is_trace_finished = true)


func get_trace_darkness() -> float:
	return _trace_material.get_shader_parameter("darkness") if _trace.visible else 0.0


func get_trace_shape() -> float:
	return _trace_material.get_shader_parameter("shape")


func _set_trace_darkness(value: float) -> void:
	_trace_material.set_shader_parameter("darkness", value)


func _set_trace_shape(value: float) -> void:
	_trace_material.set_shader_parameter("shape", value)


func get_veil_color() -> Color:
	return _veil.color
