class_name ExperienceController
extends Node3D
## Coordina las cuatro fases de la obra y comunica a los componentes cuánto se
## ha acercado el espectador a la puerta.
##
##   PROMISE    El espectador aparece; la puerta blanca brilla, lejana, en la oscuridad.
##   APPROACH   Avanza a su ritmo; luz y sonido crecen con la cercanía.
##   THRESHOLD  Ante el vano, la luz empieza a llenar la mirada.
##   ABSENCE    Cruza: resplandor blanco, después oscuridad pura y silencio.

enum Phase { PROMISE, APPROACH, THRESHOLD, ABSENCE }

signal phase_changed(phase: Phase)

## Distancia recorrida que marca el paso de la promesa a la aproximación.
@export var approach_trigger_distance: float = 0.6
## Distancia recorrida a partir de la cual se retiran las indicaciones iniciales.
@export var intro_hint_dismiss_distance: float = 3.0
## Distancia a la puerta a la que la anticipación alcanza su máximo.
@export var arrival_distance: float = 1.5
## Velocidad con la que luz y sonido siguen a la posición (más bajo = más lento).
@export var anticipation_response: float = 1.2
## Distancia a la puerta a partir de la cual la luz empieza a cubrir la pantalla.
@export var glare_distance: float = 3.5
## Opacidad máxima del resplandor justo antes de cruzar.
@export var glare_max_before_crossing: float = 0.85

var phase: Phase = Phase.PROMISE
var anticipation: float = 0.0

var _start_position: Vector3
var _path_length: float

@onready var _player: PlayerController = $Player
@onready var _door: DoorController = $Door
@onready var _final_room: FinalRoom = $FinalRoom
@onready var _audio: AudioController = $AudioController
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_start_position = _player.global_position
	_path_length = maxf(distance_to_door(), arrival_distance + 0.01)

	_final_room.player_entered.connect(_on_player_crossed)
	_final_room.player_exited.connect(_on_player_exited_beyond)

	_audio.start()


func _process(delta: float) -> void:
	var travelled := (_player.global_position - _start_position).dot(_player.path_direction)
	if phase == Phase.PROMISE and travelled >= approach_trigger_distance:
		_set_phase(Phase.APPROACH)
	if travelled >= intro_hint_dismiss_distance:
		_hud.dismiss_intro_hint()

	var distance := distance_to_door()
	if phase == Phase.APPROACH and distance <= glare_distance:
		_set_phase(Phase.THRESHOLD)

	var target := clampf(inverse_lerp(_path_length, arrival_distance, distance), 0.0, 1.0)
	anticipation = lerpf(anticipation, target, 1.0 - exp(-anticipation_response * delta))
	_door.set_anticipation(anticipation)
	_audio.set_anticipation(anticipation)

	var glare := clampf(1.0 - distance / glare_distance, 0.0, 1.0)
	_hud.set_glare(glare * glare * glare_max_before_crossing)


## Distancia del espectador a la puerta medida sobre el eje del recorrido.
func distance_to_door() -> float:
	return maxf((_door.global_position - _player.global_position).dot(_player.path_direction), 0.0)


func _on_player_crossed(_player_body: Node3D) -> void:
	_player.free_roam = true
	if phase != Phase.ABSENCE:
		_set_phase(Phase.ABSENCE)
		_hud.play_crossing()
		_door.extinguish()
		_audio.fade_to_silence()


func _on_player_exited_beyond(_player_body: Node3D) -> void:
	_player.free_roam = false


func _set_phase(new_phase: Phase) -> void:
	if new_phase <= phase:
		return
	phase = new_phase
	print_verbose("EXPECTADOOR: fase ", Phase.keys()[phase])
	phase_changed.emit(phase)
