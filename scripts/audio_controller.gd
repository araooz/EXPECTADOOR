class_name AudioController
extends Node
## Música adaptativa: guiada por la distancia y separada por fases, con el bucle
## cuantizado al compás.
##
## Antes de cruzar, la canción suena desde el inicio. Comienza casi inaudible y
## lejana, y crece y se aclara a medida que el espectador se acerca a la puerta
## (volumen y filtro paso bajo del bus "Ambience"). Si se demora, la canción no
## llega al fragmento reservado para el cruce: al terminar el último compás
## anterior vuelve al inicio del bucle.
##
## Al cruzar, la canción salta en ese mismo instante a [member crossing_cue_time]
## a volumen pleno y sin filtro. Suena hasta [member song_end_time], se desvanece
## y deja un silencio que ya no se interrumpe.

## Se emite cuando la música termina tras el cruce y queda el silencio.
signal music_finished

@export var bus_name: StringName = &"Ambience"
@export var intro_fade_duration: float = 4.0

@export_group("Respuesta a la anticipación (0 → 1)")
@export var music_volume_range_db: Vector2 = Vector2(-30.0, -2.0)
@export var lowpass_cutoff_range_hz: Vector2 = Vector2(500.0, 20000.0)

@export_group("Tempo")
@export var bpm: float = 96.0
@export var beats_per_bar: int = 4
## Segundo en que cae el primer tiempo fuerte de la canción.
@export var first_downbeat: float = 0.0

@export_group("Fragmentos (segundos)")
## Adonde vuelve el bucle si el espectador tarda en llegar a la puerta.
@export var approach_loop_start: float = 0.0
## Punto de la canción que suena al cruzar la puerta (1:43).
@export var crossing_cue_time: float = 103.0
## Fin de la música tras el cruce (2:15).
@export var song_end_time: float = 135.0
## Duración del desvanecimiento final, que termina en [member song_end_time].
@export var end_fade_duration: float = 1.0

var is_crossed: bool = false
var is_finished: bool = false

var _bus_index: int = -1
var _lowpass: AudioEffectLowPassFilter
var _anticipation: float = 0.0
var _intro_gain: float = 0.0
var _end_gain: float = 1.0
var _end_fade_started: bool = false

@onready var _music: AudioStreamPlayer = $Music


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
	if is_finished:
		return
	if _music.playing:
		var position := _music.get_playback_position()
		if not is_crossed and position >= get_approach_loop_end():
			_music.seek(approach_loop_start)
		elif is_crossed:
			if not _end_fade_started and position >= song_end_time - end_fade_duration:
				_end_fade_started = true
				create_tween().tween_property(self, "_end_gain", 0.0, end_fade_duration)
			if position >= song_end_time or _end_gain <= 0.0:
				_finish()
				return
	_apply_mix()


## Comienza la música con una entrada gradual.
func start() -> void:
	if is_crossed or _music.playing:
		return
	_music.play()
	create_tween().tween_property(self, "_intro_gain", 1.0, intro_fade_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func set_anticipation(value: float) -> void:
	if is_crossed:
		return
	_anticipation = clampf(value, 0.0, 1.0)


## Salta en el acto al fragmento del cruce, a plena intensidad. Es irreversible.
func play_crossing() -> void:
	if is_crossed:
		return
	is_crossed = true
	_intro_gain = 1.0
	_anticipation = 1.0
	_apply_mix()
	_music.play(crossing_cue_time)


## Duración de un compás en segundos.
func get_bar_length() -> float:
	return 60.0 / bpm * beats_per_bar


## Fin del bucle previo al cruce: el último límite de compás antes del fragmento
## del cruce, para que ese fragmento quede reservado para el momento de cruzar.
func get_approach_loop_end() -> float:
	var bars := floorf((crossing_cue_time - first_downbeat) / get_bar_length())
	return first_downbeat + bars * get_bar_length()


func get_music_volume_db() -> float:
	return _music.volume_db


func get_music_position() -> float:
	return _music.get_playback_position()


func get_lowpass_cutoff_hz() -> float:
	return _lowpass.cutoff_hz if _lowpass else 0.0


func is_music_playing() -> bool:
	return _music.playing


func _finish() -> void:
	is_finished = true
	_music.stop()
	music_finished.emit()


func _apply_mix() -> void:
	var gain := maxf(_intro_gain * _end_gain, 0.0001)
	# Curva suave: al principio crece despacio y se intensifica en el tramo final.
	var curve := pow(_anticipation, 1.3)
	_music.volume_db = lerpf(music_volume_range_db.x, music_volume_range_db.y, curve) + linear_to_db(gain)
	if _lowpass:
		# Interpolación exponencial: el sonido se "abre" de forma perceptualmente uniforme.
		var ratio := lowpass_cutoff_range_hz.y / lowpass_cutoff_range_hz.x
		_lowpass.cutoff_hz = lowpass_cutoff_range_hz.x * pow(ratio, _anticipation)
