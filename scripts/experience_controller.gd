class_name ExperienceController
extends Node3D
## Coordina las fases de la obra. El espectador no se desplaza por sí mismo: es
## llevado por el pasillo a un ritmo fijo, de modo que el recorrido dura siempre
## lo mismo y cruza la puerta exactamente cuando la música se corta.
##
##   DARKNESS   Negro total y silencio ([member silence_duration]).
##   PROMISE    Aparece un punto de luz a lo lejos; comienza la música, muy tenue.
##   APPROACH   El espectador avanza; la música crece y el punto toma forma de puerta.
##   THRESHOLD  Ante el vano, la luz empieza a llenar la mirada.
##   ABSENCE    Cruza: todo queda blanco y la música se corta a silencio total.
##
## Línea de tiempo (valores por defecto): 0:00–0:02,5 silencio; 0:02,5 entra la
## canción desde su 0:00; 1:48,0 cruce y corte (canción en 1:45,5).
## La duración total es [member silence_duration] + [member AudioController.cut_time].

enum Phase { DARKNESS, PROMISE, APPROACH, THRESHOLD, ABSENCE }

signal phase_changed(phase: Phase)

## Segundos de negro total y silencio antes de que aparezcan la luz y la música.
@export var silence_duration: float = 2.5
## Dirección del recorrido (el pasillo avanza hacia -Z).
@export var path_direction: Vector3 = Vector3.FORWARD
## Segundos que tarda el avance en alcanzar su velocidad de crucero al comenzar.
@export var travel_ease_in: float = 4.0
## Distancia recorrida que marca el paso de la promesa a la aproximación.
@export var approach_trigger_distance: float = 0.6
## Distancia a la puerta a la que la anticipación alcanza su máximo.
@export var arrival_distance: float = 1.5
## Velocidad con la que luz y sonido siguen a la posición (más bajo = más lento).
@export var anticipation_response: float = 1.5

@export_group("Forma de la puerta")
## Distancia a la puerta a partir de la cual el punto empieza a estirarse.
@export var shape_start_distance: float = 55.0
## Distancia a la que la puerta tiene ya su forma completa.
@export var shape_complete_distance: float = 14.0

@export_group("Luz en el suelo")
## Distancia a la puerta a la que empieza a notarse el brillo en el suelo.
@export var floor_light_start_distance: float = 32.0
## Distancia a la que el brillo del suelo alcanza su intensidad plena.
@export var floor_light_full_distance: float = 8.0

@export_group("Resplandor")
## Distancia a la puerta a partir de la cual la luz empieza a cubrir la pantalla.
@export var glare_distance: float = 3.0
## Opacidad máxima del resplandor justo antes de cruzar.
@export var glare_max_before_crossing: float = 0.85

var phase: Phase = Phase.DARKNESS
var anticipation: float = 0.0

## Segundos transcurridos desde el comienzo de la obra.
var elapsed: float = 0.0

var _start_position: Vector3
var _path_length: float
var _travel_speed: float

@onready var _player: PlayerController = $Player
@onready var _door: DoorController = $Door
@onready var _audio: AudioController = $AudioController
@onready var _hud: Hud = $Hud


func _ready() -> void:
	path_direction = path_direction.normalized()
	_start_position = _player.global_position
	_path_length = maxf(distance_to_door(), arrival_distance + 0.01)
	# Velocidad de crucero tal que, con la aceleración inicial, el espectador
	# alcanza el plano de la puerta justo al terminar la línea de tiempo.
	_travel_speed = _path_length / maxf(get_travel_duration() - travel_ease_in * 0.5, 0.01)


func _process(delta: float) -> void:
	if phase == Phase.ABSENCE:
		return
	_advance_clock(delta)
	if phase == Phase.DARKNESS and elapsed >= silence_duration:
		_reveal()
	_player.global_position = _start_position + path_direction * get_travelled_distance()
	if elapsed >= get_total_duration():
		_cross()
		return

	if phase == Phase.PROMISE and get_travelled_distance() >= approach_trigger_distance:
		_set_phase(Phase.APPROACH)

	var distance := distance_to_door()
	if phase == Phase.APPROACH and distance <= glare_distance:
		_set_phase(Phase.THRESHOLD)

	var target := clampf(inverse_lerp(_path_length, arrival_distance, distance), 0.0, 1.0)
	anticipation = lerpf(anticipation, target, 1.0 - exp(-anticipation_response * delta))
	_door.set_anticipation(anticipation)
	_door.set_shape(clampf(inverse_lerp(shape_start_distance, shape_complete_distance, distance), 0.0, 1.0))
	# Aparición gradual del brillo en el suelo: comienza casi imperceptible
	# (curva suave en ambos extremos) y crece a medida que se acorta la distancia.
	var floor_t := clampf(inverse_lerp(floor_light_start_distance, floor_light_full_distance, distance), 0.0, 1.0)
	_door.set_floor_light(smoothstep(0.0, 1.0, floor_t) * floor_t)
	_audio.set_anticipation(anticipation)

	var glare := clampf(1.0 - distance / glare_distance, 0.0, 1.0)
	_hud.set_glare(glare * glare * glare * glare_max_before_crossing)


## Duración total de la obra hasta el cruce: silencio inicial + canción hasta el corte.
func get_total_duration() -> float:
	return silence_duration + _audio.cut_time


## Duración del avance: desde que aparece la luz hasta el cruce.
func get_travel_duration() -> float:
	return get_total_duration() - silence_duration


## Metros recorridos según la línea de tiempo: aceleración suave durante
## [member travel_ease_in] y después velocidad constante hasta la puerta.
func get_travelled_distance() -> float:
	var t := clampf(elapsed - silence_duration, 0.0, get_travel_duration())
	if t < travel_ease_in:
		return _travel_speed * t * t / (2.0 * travel_ease_in)
	return _travel_speed * (t - travel_ease_in * 0.5)


## Distancia del espectador a la puerta medida sobre el eje del recorrido.
func distance_to_door() -> float:
	return maxf((_door.global_position - _player.global_position).dot(path_direction), 0.0)


## Mientras suena la canción, su posición es el reloj: así el corte de la música
## y el cruce de la puerta coinciden aunque haya tirones de imagen.
func _advance_clock(delta: float) -> void:
	if _audio.is_music_playing():
		elapsed = silence_duration + _audio.get_song_time()
	else:
		elapsed += delta


func _reveal() -> void:
	_set_phase(Phase.PROMISE)
	_door.reveal()
	_audio.start()
	_hud.show_intro_hint()


func _cross() -> void:
	_set_phase(Phase.ABSENCE)
	_hud.play_crossing()
	_door.extinguish()
	_audio.cut()


func _set_phase(new_phase: Phase) -> void:
	if new_phase <= phase:
		return
	phase = new_phase
	print_verbose("EXPECTADOOR: fase ", Phase.keys()[phase], " (%.2f s)" % elapsed)
	phase_changed.emit(phase)
