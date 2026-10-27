class_name AudioController
extends Node
## Atmósfera sonora: dos capas en bucle que crecen con la cercanía a la puerta
## y un desvanecimiento definitivo hacia el silencio.
##
## Todo el sonido de la obra (incluida la puerta) pasa por el bus "Ambience".
## Al silenciarse, ese bus se apaga y no vuelve a encenderse.

signal silence_reached

@export var bus_name: StringName = &"Ambience"
@export var intro_fade_duration: float = 4.0
@export var silence_fade_duration: float = 2.5

@export_group("Respuesta a la anticipación (0 → 1)")
@export var drone_volume_range_db: Vector2 = Vector2(-20.0, -9.0)
@export var anticipation_peak_db: float = -11.0
## Fracción del recorrido a partir de la cual empieza a oírse la capa armónica.
@export var anticipation_onset: float = 0.12
@export var lowpass_cutoff_range_hz: Vector2 = Vector2(650.0, 7000.0)

var is_silenced: bool = false

var _bus_index: int = -1
var _lowpass: AudioEffectLowPassFilter
var _anticipation: float = 0.0
var _intro_gain: float = 0.0

@onready var _drone: AudioStreamPlayer = $DroneLayer
@onready var _anticipation_layer: AudioStreamPlayer = $AnticipationLayer


func _ready() -> void:
	_bus_index = AudioServer.get_bus_index(bus_name)
	if _bus_index == -1:
		push_error("AudioController: no existe el bus '%s'." % bus_name)
		return
	AudioServer.set_bus_mute(_bus_index, false)
	AudioServer.set_bus_volume_db(_bus_index, 0.0)
	for i in AudioServer.get_bus_effect_count(_bus_index):
		var effect := AudioServer.get_bus_effect(_bus_index, i)
		if effect is AudioEffectLowPassFilter:
			_lowpass = effect
	_apply_mix()


func _process(_delta: float) -> void:
	if not is_silenced:
		_apply_mix()


## Comienza la atmósfera con una entrada gradual.
func start() -> void:
	if is_silenced or _drone.playing:
		return
	_drone.play()
	_anticipation_layer.play()
	create_tween().tween_property(self, "_intro_gain", 1.0, intro_fade_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func set_anticipation(value: float) -> void:
	if is_silenced:
		return
	_anticipation = clampf(value, 0.0, 1.0)


## Desvanece todo el sonido hasta el silencio absoluto. Es irreversible.
func fade_to_silence() -> void:
	if is_silenced or _bus_index == -1:
		return
	is_silenced = true
	var tween := create_tween()
	# Una rampa lineal en dB equivale a un decaimiento exponencial natural.
	tween.tween_method(_set_bus_volume_db, AudioServer.get_bus_volume_db(_bus_index),
			-60.0, silence_fade_duration)
	tween.tween_callback(_finish_silence)


func get_drone_volume_db() -> float:
	return _drone.volume_db


func get_anticipation_volume_db() -> float:
	return _anticipation_layer.volume_db


func get_bus_volume_db() -> float:
	return AudioServer.get_bus_volume_db(_bus_index)


func is_bus_muted() -> bool:
	return AudioServer.is_bus_mute(_bus_index)


func is_any_layer_playing() -> bool:
	return _drone.playing or _anticipation_layer.playing


func _apply_mix() -> void:
	var gain := maxf(_intro_gain, 0.0001)
	var drone_db := lerpf(drone_volume_range_db.x, drone_volume_range_db.y, _anticipation)
	_drone.volume_db = drone_db + linear_to_db(gain)

	var layer := smoothstep(anticipation_onset, 1.0, _anticipation)
	var layer_amplitude := pow(layer, 1.4) * db_to_linear(anticipation_peak_db) * gain
	_anticipation_layer.volume_db = linear_to_db(maxf(layer_amplitude, 0.00001))

	if _lowpass:
		# Interpolación exponencial: el sonido se "abre" de forma perceptualmente uniforme.
		var ratio := lowpass_cutoff_range_hz.y / lowpass_cutoff_range_hz.x
		_lowpass.cutoff_hz = lowpass_cutoff_range_hz.x * pow(ratio, _anticipation)


func _set_bus_volume_db(value: float) -> void:
	AudioServer.set_bus_volume_db(_bus_index, value)


func _finish_silence() -> void:
	AudioServer.set_bus_volume_db(_bus_index, -80.0)
	AudioServer.set_bus_mute(_bus_index, true)
	_drone.stop()
	_anticipation_layer.stop()
	silence_reached.emit()
