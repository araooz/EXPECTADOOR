class_name AudioController
extends Node
## Música: comienza casi inaudible y lejana cuando aparece la luz, y crece y se
## aclara a medida que el espectador se acerca a la puerta.
##
## Todo el sonido de la obra pasa por el bus "Ambience", cuyo filtro paso bajo
## se abre con la cercanía. Al cruzar la puerta, la música se corta de golpe:
## silencio absoluto, que ya no se interrumpe.

signal silence_reached

@export var bus_name: StringName = &"Ambience"
@export var intro_fade_duration: float = 4.0

@export_group("Respuesta a la anticipación (0 → 1)")
@export var music_volume_range_db: Vector2 = Vector2(-30.0, -2.0)
@export var lowpass_cutoff_range_hz: Vector2 = Vector2(500.0, 20000.0)

var is_silenced: bool = false

var _bus_index: int = -1
var _lowpass: AudioEffectLowPassFilter
var _anticipation: float = 0.0
var _intro_gain: float = 0.0

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
	if not is_silenced:
		_apply_mix()


## Comienza la música con una entrada gradual.
func start() -> void:
	if is_silenced or _music.playing:
		return
	_music.play()
	create_tween().tween_property(self, "_intro_gain", 1.0, intro_fade_duration) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func set_anticipation(value: float) -> void:
	if is_silenced:
		return
	_anticipation = clampf(value, 0.0, 1.0)


## Corta todo el sonido al instante: silencio absoluto. Es irreversible.
func cut_to_silence() -> void:
	if is_silenced or _bus_index == -1:
		return
	is_silenced = true
	AudioServer.set_bus_volume_db(_bus_index, -80.0)
	AudioServer.set_bus_mute(_bus_index, true)
	_music.stop()
	silence_reached.emit()


func get_music_volume_db() -> float:
	return _music.volume_db


func get_bus_volume_db() -> float:
	return AudioServer.get_bus_volume_db(_bus_index)


func is_bus_muted() -> bool:
	return AudioServer.is_bus_mute(_bus_index)


func is_music_playing() -> bool:
	return _music.playing


func _apply_mix() -> void:
	var gain := maxf(_intro_gain, 0.0001)
	# Curva suave: al principio crece despacio y se intensifica en el tramo final.
	var curve := pow(_anticipation, 1.3)
	_music.volume_db = lerpf(music_volume_range_db.x, music_volume_range_db.y, curve) + linear_to_db(gain)
	if _lowpass:
		# Interpolación exponencial: el sonido se "abre" de forma perceptualmente uniforme.
		var ratio := lowpass_cutoff_range_hz.y / lowpass_cutoff_range_hz.x
		_lowpass.cutoff_hz = lowpass_cutoff_range_hz.x * pow(ratio, _anticipation)

