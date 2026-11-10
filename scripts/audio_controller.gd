class_name AudioController
extends Node
## La música: comienza casi inaudible y lejana y crece y se aclara a medida que
## el espectador se acerca a la puerta (volumen y filtro paso bajo del bus
## "Ambience").
##
## Al cruzar la puerta ([member crossing_time]) la canción no se corta: sigue
## sonando, pero se aleja en una transición suave hasta volverse el eco ausente
## (pierde los agudos, gana reverberación y baja de volumen), como si llegara
## desde otra habitación. Lo que se oye es lo que la canción traía después del
## clímax: lo que habría venido. El eco se sostiene, se desvanece y deja un
## silencio que ya no se interrumpe.
##
## La posición de la canción es el reloj maestro de la obra: el recorrido se
## sincroniza con ella (ver [method get_song_time]).

## Se emite cuando el eco termina y queda el silencio.
signal music_finished

@export var bus_name: StringName = &"Ambience"
@export var intro_fade_duration: float = 4.0

@export_group("Respuesta a la anticipación (0 → 1)")
@export var music_volume_range_db: Vector2 = Vector2(-30.0, -2.0)
@export var lowpass_cutoff_range_hz: Vector2 = Vector2(500.0, 20000.0)

@export_group("Cruce")
## Punto de la canción que coincide con el cruce de la puerta. El clímax se
## sostiene hasta ~104,7 s; desde ~105,8 s entra un pasaje más apagado.
@export var crossing_time: float = 105.5

@export_group("Eco ausente")
## Volumen del eco una vez completada la transición.
@export var echo_volume_db: float = -30.0
## Frecuencia de corte del paso bajo en el eco (sonido "desde otra habitación").
@export var echo_lowpass_hz: float = 450.0
## Mezcla de la reverberación en el eco (durante el recorrido es 0 y 1: sin efecto).
@export var echo_reverb_wet: float = 0.6
@export var echo_reverb_dry: float = 0.5

var is_crossed: bool = false
var is_finished: bool = false

var _bus_index: int = -1
var _lowpass: AudioEffectLowPassFilter
var _reverb: AudioEffectReverb
var _anticipation: float = 0.0
var _intro_gain: float = 0.0
var _end_gain: float = 1.0
## 0 = la canción tal como sonaba al cruzar, 1 = eco ausente.
var _echo_mix: float = 0.0
var _volume_at_crossing_db: float = 0.0
var _cutoff_at_crossing_hz: float = 20000.0

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
		elif effect is AudioEffectReverb:
			_reverb = effect
	_apply_mix()


func _process(_delta: float) -> void:
	if not is_finished:
		_apply_mix()


## Comienza la música desde 0:00 con una entrada gradual.
func start() -> void:
	if is_crossed or _music.playing:
		return
	_music.play()
	create_tween().tween_property(self, "_intro_gain", 1.0, intro_fade_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func set_anticipation(value: float) -> void:
	if not is_crossed:
		_anticipation = clampf(value, 0.0, 1.0)


## Al cruzar: la canción se aleja hasta ser el eco ausente ([param transition] s),
## se sostiene ([param hold] s) y se desvanece ([param fade_out] s). Es irreversible.
func play_echo(transition: float, hold: float, fade_out: float) -> void:
	if is_crossed:
		return
	is_crossed = true
	_intro_gain = 1.0
	_volume_at_crossing_db = _music.volume_db
	_cutoff_at_crossing_hz = get_lowpass_cutoff_hz() if _lowpass else lowpass_cutoff_range_hz.y
	var tween := create_tween()
	tween.tween_property(self, "_echo_mix", 1.0, transition) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(hold)
	tween.tween_property(self, "_end_gain", 0.0, fade_out) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(_finish)


## Posición de la canción en segundos, interpolada entre mezclas de audio.
func get_song_time() -> float:
	if not _music.playing:
		return 0.0
	return _music.get_playback_position() + AudioServer.get_time_since_last_mix() * _music.pitch_scale


## Solo para desarrollo ([DevSpeed]): reproduce la canción más rápido.
func set_playback_speed(value: float) -> void:
	_music.pitch_scale = value


func get_music_volume_db() -> float:
	return _music.volume_db


func get_lowpass_cutoff_hz() -> float:
	return _lowpass.cutoff_hz if _lowpass else 0.0


func get_reverb_wet() -> float:
	return _reverb.wet if _reverb else 0.0


func get_echo_mix() -> float:
	return _echo_mix


func is_music_playing() -> bool:
	return _music.playing


func _finish() -> void:
	is_finished = true
	_music.stop()
	music_finished.emit()


func _apply_mix() -> void:
	var gain := maxf(_intro_gain * _end_gain, 0.0001)
	if is_crossed:
		_apply_echo_mix(gain)
		return
	# Curva suave: al principio crece despacio y se intensifica en el tramo final.
	var curve := pow(_anticipation, 1.3)
	_music.volume_db = lerpf(music_volume_range_db.x, music_volume_range_db.y, curve) + linear_to_db(gain)
	if _lowpass:
		# Interpolación exponencial: el sonido se "abre" de forma perceptualmente uniforme.
		var ratio := lowpass_cutoff_range_hz.y / lowpass_cutoff_range_hz.x
		_lowpass.cutoff_hz = lowpass_cutoff_range_hz.x * pow(ratio, _anticipation)


func _apply_echo_mix(gain: float) -> void:
	var m := _echo_mix
	_music.volume_db = lerpf(_volume_at_crossing_db, echo_volume_db, m) + linear_to_db(gain)
	if _lowpass:
		_lowpass.cutoff_hz = _cutoff_at_crossing_hz * pow(echo_lowpass_hz / _cutoff_at_crossing_hz, m)
	if _reverb:
		_reverb.wet = lerpf(0.0, echo_reverb_wet, m)
		_reverb.dry = lerpf(1.0, echo_reverb_dry, m)
