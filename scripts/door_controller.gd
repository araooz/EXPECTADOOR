class_name DoorController
extends Node3D
## La puerta: una luz blanca pura. Aparece como un punto lejano y, a medida que
## el espectador se acerca, toma la forma del vano. No se abre; se atraviesa.
##
## El foco Beam, situado detrás del muro, proyecta a través del vano el haz que
## se extiende por el suelo. La luz del suelo (haz y halo) tiene su propio
## control, set_floor_light(), para que solo aparezca al acercarse.

@export var reveal_duration: float = 3.0

@export_group("Luz según la anticipación (0 → 1)")
@export var beam_energy_range: Vector2 = Vector2(10.0, 16.0)
@export var halo_energy_range: Vector2 = Vector2(0.1, 0.45)
@export var plane_energy_range: Vector2 = Vector2(2.5, 3.5)
## Brillo adicional del punto lejano, para que su halo sea visible a distancia.
@export var point_energy_boost: float = 4.0
## Intensidad del halo esférico que rodea al punto lejano.
@export var point_glow_strength: float = 1.6

var is_revealed: bool = false
var is_extinguished: bool = false

var _reveal: float = 0.0
var _shape: float = 0.0
var _anticipation: float = 0.0
var _floor_light: float = 0.0

@onready var _light_plane: MeshInstance3D = $LightPlane
@onready var _material: ShaderMaterial = _light_plane.get_active_material(0)
@onready var _point_glow: MeshInstance3D = $PointGlow
@onready var _glow_material: ShaderMaterial = _point_glow.get_active_material(0)
@onready var _beam: SpotLight3D = $Beam
@onready var _halo: OmniLight3D = $Halo


func _ready() -> void:
	_apply()


## Hace aparecer el punto de luz en la oscuridad.
func reveal() -> void:
	if is_revealed:
		return
	is_revealed = true
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_reveal = v
		_apply(), 0.0, 1.0, reveal_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## 0 = punto, 1 = forma completa de la puerta.
func set_shape(value: float) -> void:
	_shape = clampf(value, 0.0, 1.0)
	_apply()


## Presencia de la luz en el suelo (0 = nada, 1 = haz completo).
func set_floor_light(value: float) -> void:
	_floor_light = clampf(value, 0.0, 1.0)
	_apply()


## Intensidad de la anticipación (0 al comienzo del pasillo, 1 ante la puerta).
func set_anticipation(value: float) -> void:
	_anticipation = clampf(value, 0.0, 1.0)
	_apply()


## Apaga la puerta para siempre.
func extinguish() -> void:
	is_extinguished = true
	_light_plane.hide()
	_point_glow.hide()
	_beam.hide()
	_halo.hide()


func get_shape() -> float:
	return _shape


func _apply() -> void:
	if not is_node_ready() or is_extinguished:
		return
	var a := _anticipation
	_material.set_shader_parameter("reveal", _reveal)
	_material.set_shader_parameter("shape", _shape)
	var boost := lerpf(point_energy_boost, 1.0, _shape)
	_material.set_shader_parameter("energy", lerpf(plane_energy_range.x, plane_energy_range.y, a) * boost)
	# El halo esférico pertenece al punto: desaparece cuando la puerta toma forma.
	var point := 1.0 - smoothstep(0.0, 0.6, _shape)
	_glow_material.set_shader_parameter("strength", point_glow_strength * point * _reveal)
	_point_glow.visible = point * _reveal > 0.001
	# La luz del suelo: mientras solo se ve el punto, el suelo permanece negro.
	var floor_amount := _floor_light * _reveal
	_beam.light_energy = lerpf(beam_energy_range.x, beam_energy_range.y, a) * floor_amount
	_beam.visible = _beam.light_energy > 0.001
	_halo.light_energy = lerpf(halo_energy_range.x, halo_energy_range.y, a) * floor_amount
	_halo.visible = _halo.light_energy > 0.001
