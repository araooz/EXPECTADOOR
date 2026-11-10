class_name Hud
extends CanvasLayer
## Capa mínima de interfaz: indicaciones iniciales discretas y el velo del
## cruce (el resplandor crece ante la puerta y, al cruzarla, todo queda blanco).

@export var intro_hint_hold: float = 7.0
@export var hint_fade_duration: float = 1.2
@export var hint_opacity: float = 0.45
## Duración del paso al blanco total al cruzar.
@export var crossing_white_duration: float = 0.4

var _intro_tween: Tween
var _intro_shown: bool = false
var _crossed: bool = false

@onready var _veil: ColorRect = $Veil
@onready var _intro_hint: Label = $IntroHint


func _ready() -> void:
	_veil.color = Color(1, 1, 1, 0)
	_intro_hint.modulate.a = 0.0


## Muestra brevemente las indicaciones de control.
func show_intro_hint() -> void:
	if _intro_shown:
		return
	_intro_shown = true
	_intro_tween = create_tween()
	_intro_tween.tween_property(_intro_hint, "modulate:a", hint_opacity, hint_fade_duration)
	_intro_tween.tween_interval(intro_hint_hold)
	_intro_tween.tween_property(_intro_hint, "modulate:a", 0.0, hint_fade_duration)


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
	_intro_hint.hide()
	create_tween().tween_property(_veil, "color", Color(1, 1, 1, 1), crossing_white_duration)


func get_veil_color() -> Color:
	return _veil.color
