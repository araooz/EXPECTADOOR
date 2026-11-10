class_name PlayerController
extends Node3D
## El espectador en primera persona. No puede desplazarse: solo girar la mirada
## en cualquier dirección. Su posición la fija [ExperienceController], que lo
## lleva por el pasillo a un ritmo sincronizado con la música.

@export_group("Mirada")
@export var mouse_sensitivity: float = 0.0022
@export var look_smoothing: float = 12.0
## Límite vertical de la mirada (por debajo de 90° para que la vista no se invierta).
@export var pitch_limit_degrees: float = 89.0

var _yaw: float = 0.0
var _pitch: float = 0.0
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	_capture_mouse(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse_capture"):
		_capture_mouse(Input.mouse_mode != Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse(true)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		_target_yaw -= motion.relative.x * mouse_sensitivity
		_target_pitch -= motion.relative.y * mouse_sensitivity


func _process(delta: float) -> void:
	var pitch_limit := deg_to_rad(pitch_limit_degrees)
	_target_pitch = clampf(_target_pitch, -pitch_limit, pitch_limit)

	var weight := 1.0 - exp(-look_smoothing * delta)
	_yaw = lerpf(_yaw, _target_yaw, weight)
	_pitch = lerpf(_pitch, _target_pitch, weight)
	_head.rotation.y = _yaw
	_camera.rotation.x = _pitch


## Fija el objetivo de la mirada en grados (se respeta el límite vertical).
func set_look_target(yaw_degrees: float, pitch_degrees: float) -> void:
	_target_yaw = deg_to_rad(yaw_degrees)
	_target_pitch = deg_to_rad(pitch_degrees)


func get_look_yaw_degrees() -> float:
	return rad_to_deg(_yaw)


func get_camera() -> Camera3D:
	return _camera


func _capture_mouse(capture: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
