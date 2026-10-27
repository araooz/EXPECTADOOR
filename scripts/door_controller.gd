class_name DoorController
extends Node3D
## La puerta: su luz, su apertura y la zona desde la que puede abrirse.
##
## La hoja (Leaf) tiene su origen en las bisagras del borde izquierdo y se
## abre hacia la habitación, alejándose del espectador. Antes de abrirse, una
## franja de luz cálida se filtra por las rendijas del marco; esa luz se apaga
## en cuanto la puerta se abre.

signal interaction_available_changed(available: bool)
signal opening_started
signal opened

@export var open_angle_degrees: float = 96.0
@export var open_duration: float = 4.5
## Pausa entre el sonido del picaporte y el inicio del giro.
@export var latch_delay: float = 0.35
@export var leak_fade_duration: float = 0.8

@export_group("Luz según la anticipación (0 → 1)")
@export var lamp_energy_range: Vector2 = Vector2(1.6, 4.2)
@export var leak_light_energy_range: Vector2 = Vector2(0.35, 1.1)
@export var leak_glow_energy_range: Vector2 = Vector2(2.5, 6.0)

var is_open: bool = false
var is_opening: bool = false

var _player_in_range: bool = false
var _anticipation: float = 0.0
var _leak_strength: float = 1.0

@onready var _leaf: AnimatableBody3D = $Leaf
@onready var _interaction_area: Area3D = $InteractionArea
@onready var _lamp: SpotLight3D = $DoorLamp
@onready var _leak_light: OmniLight3D = $LeakLight
@onready var _leak_glow: MeshInstance3D = $LeakGlow
@onready var _leak_material: StandardMaterial3D = _leak_glow.get_active_material(0)
@onready var _open_sound: AudioStreamPlayer3D = $OpenSound


func _ready() -> void:
	_interaction_area.body_entered.connect(_on_body_entered)
	_interaction_area.body_exited.connect(_on_body_exited)
	_apply_lighting()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_open():
		get_viewport().set_input_as_handled()
		open()


func can_open() -> bool:
	return _player_in_range and not is_opening and not is_open


## Intensidad de la anticipación (0 al comienzo del pasillo, 1 ante la puerta).
func set_anticipation(value: float) -> void:
	_anticipation = clampf(value, 0.0, 1.0)
	_apply_lighting()


func open() -> void:
	if is_opening or is_open:
		return
	is_opening = true
	_set_player_in_range(false)
	_interaction_area.set_deferred("monitoring", false)
	_open_sound.play()
	opening_started.emit()

	var leak_tween := create_tween()
	leak_tween.tween_property(self, "_leak_strength", 0.0, leak_fade_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	leak_tween.parallel().tween_method(func(_v: float) -> void: _apply_lighting(),
			0.0, 1.0, leak_fade_duration)
	leak_tween.tween_callback(_leak_glow.hide)

	# La hoja es un AnimatableBody3D: se anima en el paso de física para que
	# su colisión acompañe al giro.
	var swing := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	swing.tween_interval(latch_delay)
	swing.tween_property(_leaf, "rotation:y", deg_to_rad(open_angle_degrees), open_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_callback(_on_swing_finished)


func _on_swing_finished() -> void:
	is_opening = false
	is_open = true
	opened.emit()


func _apply_lighting() -> void:
	if not is_node_ready():
		return
	var a := _anticipation
	_lamp.light_energy = lerpf(lamp_energy_range.x, lamp_energy_range.y, a)
	_leak_light.light_energy = lerpf(leak_light_energy_range.x, leak_light_energy_range.y, a) * _leak_strength
	_leak_light.visible = _leak_strength > 0.001
	_leak_material.emission_energy_multiplier = lerpf(leak_glow_energy_range.x, leak_glow_energy_range.y, a)
	_leak_material.albedo_color.a = _leak_strength


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not is_opening and not is_open:
		_set_player_in_range(true)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_set_player_in_range(false)


func _set_player_in_range(value: bool) -> void:
	if _player_in_range == value:
		return
	_player_in_range = value
	interaction_available_changed.emit(value)
