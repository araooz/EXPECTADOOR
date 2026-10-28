class_name PlayerController
extends CharacterBody3D
## Controlador en primera persona para un recorrido guiado.
##
## La mirada puede girar libremente en cualquier dirección. En el pasillo el
## desplazamiento sigue el eje del recorrido; en la habitación final (modo
## [member free_roam]) se camina hacia donde se mira.

@export_group("Movimiento")
@export var walk_speed: float = 3.2
@export var acceleration: float = 3.5
@export var deceleration: float = 5.0
## Dirección del recorrido en el pasillo (el pasillo avanza hacia -Z).
@export var path_direction: Vector3 = Vector3.FORWARD

@export_group("Mirada")
@export var mouse_sensitivity: float = 0.0022
@export var look_smoothing: float = 12.0
## Límite vertical de la mirada (por debajo de 90° para que la vista no se invierta).
@export var pitch_limit_degrees: float = 89.0

## Si es verdadero, se camina en la dirección de la mirada (habitación final).
var free_roam: bool = false

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _yaw: float = 0.0
var _pitch: float = 0.0
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D


func _ready() -> void:
	path_direction = path_direction.normalized()
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


func _physics_process(delta: float) -> void:
	var input_axis := Input.get_axis("move_back", "move_forward")
	var direction := path_direction
	if free_roam:
		direction = -_head.global_basis.z
		direction.y = 0.0
		direction = direction.normalized()

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var target := direction * input_axis * walk_speed
	var rate := acceleration if not is_zero_approx(input_axis) else deceleration
	horizontal = horizontal.move_toward(target, rate * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta

	move_and_slide()


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
