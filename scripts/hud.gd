class_name Hud
extends CanvasLayer
## Capa mínima de interfaz: fundido desde negro, indicaciones iniciales
## discretas y el indicador contextual para abrir la puerta.

@export var fade_in_duration: float = 3.5
@export var intro_hint_delay: float = 2.0
@export var intro_hint_hold: float = 9.0
@export var hint_fade_duration: float = 1.2
@export var hint_opacity: float = 0.55

var _intro_tween: Tween
var _interact_tween: Tween
var _intro_dismissed: bool = false

@onready var _fade: ColorRect = $Fade
@onready var _intro_hint: Label = $IntroHint
@onready var _interact_hint: Label = $InteractHint


func _ready() -> void:
	_fade.modulate.a = 1.0
	_intro_hint.modulate.a = 0.0
	_interact_hint.modulate.a = 0.0
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


func set_interaction_hint_visible(hint_visible: bool) -> void:
	if _interact_tween:
		_interact_tween.kill()
	_interact_tween = create_tween()
	_interact_tween.tween_property(_interact_hint, "modulate:a",
			hint_opacity if hint_visible else 0.0, 0.6 if hint_visible else 0.4)


func is_interaction_hint_shown() -> bool:
	return _interact_hint.modulate.a > 0.01
