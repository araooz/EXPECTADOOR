class_name Hud
extends CanvasLayer
## Capa mínima de interfaz: fundido desde negro, indicaciones iniciales
## discretas y el velo del cruce (resplandor blanco y después oscuridad).

@export var fade_in_duration: float = 3.5
@export var intro_hint_delay: float = 2.0
@export var intro_hint_hold: float = 9.0
@export var hint_fade_duration: float = 1.2
@export var hint_opacity: float = 0.55

@export_group("Cruce")
## Tiempo que la pantalla permanece completamente blanca tras cruzar.
@export var glare_hold: float = 1.2
## Duración del paso del blanco al negro.
@export var glare_to_dark_duration: float = 3.0

var _intro_tween: Tween
var _intro_dismissed: bool = false
var _crossed: bool = false

@onready var _fade: ColorRect = $Fade
@onready var _veil: ColorRect = $Veil
@onready var _intro_hint: Label = $IntroHint


func _ready() -> void:
	_fade.modulate.a = 1.0
	_veil.color = Color(1, 1, 1, 0)
	_intro_hint.modulate.a = 0.0
	create_tween().tween_property(_fade, "modulate:a", 0.0, fade_in_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_intro_tween = create_tween()
	_intro_tween.tween_interval(intro_hint_delay)
	_intro_tween.tween_property(_intro_hint, "modulate:a", hint_opacity, hint_fade_duration)
	_intro_tween.tween_interval(intro_hint_hold)
	_intro_tween.tween_property(_intro_hint, "modulate:a", 0.0, hint_fade_duration)


## Retira las indicaciones iniciales cuando ya no son necesarias.
func dismiss_intro_hint() -> void:
	if _intro_dismissed:
		return
	_intro_dismissed = true
	if _intro_tween:
		_intro_tween.kill()
	_intro_tween = create_tween()
	_intro_tween.tween_property(_intro_hint, "modulate:a", 0.0, hint_fade_duration)


## Resplandor previo al cruce (0 = nada, 1 = pantalla blanca).
func set_glare(amount: float) -> void:
	if _crossed:
		return
	_veil.color.a = clampf(amount, 0.0, 1.0)


## Al cruzar: blanco total, y luego oscuridad pura que ya no se retira.
func play_crossing() -> void:
	if _crossed:
		return
	_crossed = true
	_veil.color = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_interval(glare_hold)
	tween.tween_property(_veil, "color", Color(0, 0, 0, 1), glare_to_dark_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func get_veil_color() -> Color:
	return _veil.color
