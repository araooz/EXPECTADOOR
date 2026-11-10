class_name AudioController
extends Node
## La música: comienza casi inaudible y lejana y crece y se aclara a medida que
## el espectador se acerca a la puerta (volumen y filtro paso bajo del bus
## "Ambience"). Al llegar a [member cut_time] se corta de golpe, en pleno
## clímax, y deja un silencio que ya no se interrumpe.
##
## La posición de la canción es el reloj maestro de la obra: el recorrido se
## sincroniza con ella (ver [method get_song_time]).

## Se emite cuando la música se corta y queda el silencio.
signal music_finished

@export var bus_name: StringName = &"Ambience"
@export var intro_fade_duration: float = 4.0

@export_group("Respuesta a la anticipación (0 → 1)")
@export var music_volume_range_db: Vector2 = Vector2(-30.0, -2.0)
@export var lowpass_cutoff_range_hz: Vector2 = Vector2(500.0, 20000.0)

@export_group("Corte")
## Punto de la canción en que se corta a silencio (coincide con el cruce de la puerta).
## El clímax de la canción se sostiene hasta ~104,7 s.
@export var cut_time: float = 103.5
## Rampa mínima al cortar, solo para evitar un chasquido; se percibe como un corte seco.
@export var cut_ramp_duration: float = 0.02

var is_finished: bool = false

var _bus_index: int = -1
var _lowpass: AudioEffectLowPassFilter
var _anticipation: float = 0.0
var _intro_gain: float = 0.0
var _end_gain: float = 1.0

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
	if _music.playing and get_song_time() >= cut_time:
		cut()
		return
	_apply_mix()


## Comienza la música desde 0:00 con una entrada gradual.
func start() -> void:
	if is_finished or _music.playing:
		return
	_music.play()
	create_tween().tween_property(self, "_intro_gain", 1.0, intro_fade_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func set_anticipation(value: float) -> void:
	_anticipation = clampf(value, 0.0, 1.0)


## Corta la música a silencio total. Es irreversible.
func cut() -> void:
	if is_finished:
		return
	is_finished = true
	var tween := create_tween()
	tween.tween_method(func(g: float) -> void:
		_end_gain = g
		_apply_mix(), 1.0, 0.0, cut_ramp_duration)
	tween.tween_callback(_music.stop)
	tween.tween_callback(music_finished.emit)


## Posición de la canción en segundos, interpolada entre mezclas de audio.
func get_song_time() -> float:
	if not _music.playing:
		return 0.0
	return _music.get_playback_position() + AudioServer.get_time_since_last_mix()


func get_music_volume_db() -> float:
	return _music.volume_db


func get_lowpass_cutoff_hz() -> float:
	return _lowpass.cutoff_hz if _lowpass else 0.0


func is_music_playing() -> bool:
	return _music.playing


func _apply_mix() -> void:
	var gain := maxf(_intro_gain * _end_gain, 0.0001)
	# Curva suave: al principio crece despacio y se intensifica en el tramo final.
	var curve := pow(_anticipation, 1.3)
	_music.volume_db = lerpf(music_volume_range_db.x, music_volume_range_db.y, curve) + linear_to_db(gain)
	if _lowpass:
		# Interpolación exponencial: el sonido se "abre" de forma perceptualmente uniforme.
		var ratio := lowpass_cutoff_range_hz.y / lowpass_cutoff_range_hz.x
		_lowpass.cutoff_hz = lowpass_cutoff_range_hz.x * pow(ratio, _anticipation)
