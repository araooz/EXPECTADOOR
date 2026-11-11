class_name PlayerController
extends Node3D
## El espectador en primera persona. No puede desplazarse: solo girar la mirada
## en cualquier dirección. Su posición la fija [ExperienceController], que lo
## lleva por el pasillo a un ritmo sincronizado con la música.
##
## Con lentes VR (OpenXR) la mirada es la de la cabeza: se usa la XRCamera3D y
## el ratón no interviene. Sin visor, se mira con el ratón.

## Se emite cuando la experiencia puede empezar: de inmediato sin visor; con
## visor, cuando la sesión VR tiene el foco (el visor está puesto y la app al frente).
signal ready_to_start

@export_group("Mirada")
@export var mouse_sensitivity: float = 0.0022
@export var look_smoothing: float = 12.0
## Límite vertical de la mirada (por debajo de 90° para que la vista no se invierta).
@export var pitch_limit_degrees: float = 89.0

## Verdadero si la experiencia se ve a través de lentes VR.
var is_xr: bool = false

var _xr_interface: XRInterface
var _started: bool = false
var _yaw: float = 0.0
var _pitch: float = 0.0
var _target_yaw: float = 0.0
var _target_pitch: float = 0.0

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _xr_origin: XROrigin3D = $XROrigin3D
@onready var _xr_camera: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var _xr_overlay: XrOverlay = $XROrigin3D/XRCamera3D/XrOverlay


func _ready() -> void:
	_xr_interface = XRServer.find_interface("OpenXR")
	if _xr_interface and _xr_interface.is_initialized():
		_enable_xr()
	else:
		_capture_mouse(true)
		_emit_ready_to_start.call_deferred()


func _enable_xr() -> void:
	is_xr = true
	get_viewport().use_xr = true
	# El visor marca su propio ritmo; la sincronización vertical del monitor lo frenaría.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_xr_origin.current = true
	_xr_camera.current = true
	_xr_overlay.show()
	_xr_interface.session_focussed.connect(_on_xr_session_focussed)
	_xr_interface.pose_recentered.connect(_center_view)


## Sitúa la vista: la cabeza en el origen (a la altura de los ojos de la escena)
## y mirando hacia la puerta, sea cual sea la orientación de la silla.
func _center_view() -> void:
	XRServer.center_on_hmd(XRServer.RESET_BUT_KEEP_TILT, false)


func _on_xr_session_focussed() -> void:
	_center_view()
	_emit_ready_to_start()


func _emit_ready_to_start() -> void:
	if _started:
		return
	_started = true
	ready_to_start.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_mouse_capture"):
		_capture_mouse(Input.mouse_mode != Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_capture_mouse(true)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not is_xr:
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
	return _xr_camera if is_xr else _camera


func get_xr_overlay() -> XrOverlay:
	return _xr_overlay


func _capture_mouse(capture: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if capture else Input.MOUSE_MODE_VISIBLE
