class_name DoorController
extends Node3D
## La puerta: un vano que emite luz blanca pura. No se abre; se atraviesa.
##
## El foco Beam, situado detrás del muro, proyecta a través del vano el haz que
## se extiende por el suelo del pasillo. Al cruzar, la luz se extingue.

@export_group("Luz según la anticipación (0 → 1)")
@export var beam_energy_range: Vector2 = Vector2(11.0, 16.0)
@export var halo_energy_range: Vector2 = Vector2(0.25, 0.5)

var is_extinguished: bool = false

@onready var _light_plane: MeshInstance3D = $LightPlane
@onready var _beam: SpotLight3D = $Beam
@onready var _halo: OmniLight3D = $Halo


## Intensidad de la anticipación (0 al comienzo del pasillo, 1 ante la puerta).
func set_anticipation(value: float) -> void:
	if is_extinguished:
		return
	var a := clampf(value, 0.0, 1.0)
	_beam.light_energy = lerpf(beam_energy_range.x, beam_energy_range.y, a)
	_halo.light_energy = lerpf(halo_energy_range.x, halo_energy_range.y, a)


## Apaga la puerta para siempre: detrás de ella no queda nada.
func extinguish() -> void:
	is_extinguished = true
	_light_plane.hide()
	_beam.hide()
	_halo.hide()
