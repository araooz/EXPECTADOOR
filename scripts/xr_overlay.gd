class_name XrOverlay
extends Node3D
## En VR, el velo y la huella del Hud no se ven (la capa 2D no llega al visor).
## Este nodo, hijo de la XRCamera3D, los reproduce como quads pegados a la
## cabeza. El Hud le copia su estado en cada frame (ver [method Hud.use_xr_overlay]).

## El velo se dibuja antes del tonemapping, que comprime mucho los blancos: un
## 2 % de velo ya se ve al 41 % de brillo. Esta tabla (medida: alpha del velo →
## brillo en pantalla sobre negro, con el entorno de main.tscn) se invierte para
## que el resplandor en VR se vea igual de intenso que el velo 2D del Hud.
const VEIL_ALPHA := [0.0, 0.001, 0.002, 0.003, 0.005, 0.0075, 0.01, 0.0125, 0.015, 0.02, 0.025,
		0.03, 0.04, 0.05, 0.065, 0.08, 0.1, 0.13, 0.16, 0.2, 0.25, 0.3, 0.4, 0.55, 0.7, 0.85]
const VEIL_BRIGHTNESS := [0.0, 0.016, 0.047, 0.078, 0.133, 0.192, 0.247, 0.294, 0.337, 0.412, 0.475,
		0.525, 0.612, 0.675, 0.741, 0.788, 0.831, 0.875, 0.902, 0.925, 0.949, 0.965, 0.984, 0.992, 0.996, 1.0]

@onready var _veil: MeshInstance3D = $Veil
@onready var _veil_material: ShaderMaterial = _veil.get_active_material(0)
@onready var _trace: MeshInstance3D = $Trace
@onready var _trace_material: ShaderMaterial = _trace.get_active_material(0)


func apply(veil_alpha: float, trace_visible: bool, trace_darkness: float, trace_shape: float) -> void:
	_veil.visible = veil_alpha > 0.0001
	# Blanco total: tras el cruce el entorno usa tonemapping lineal (ver xr_veil.gdshader).
	var full := veil_alpha >= 0.999
	_veil_material.set_shader_parameter("alpha", 1.0 if full else veil_alpha_for_brightness(veil_alpha))
	_veil_material.set_shader_parameter("white_level", 1.0 if full else 6.0)
	_trace.visible = trace_visible
	_trace_material.set_shader_parameter("darkness", trace_darkness)
	_trace_material.set_shader_parameter("shape", trace_shape)


## Alpha del velo VR que produce el brillo [param brightness] (interpolando la tabla medida).
static func veil_alpha_for_brightness(brightness: float) -> float:
	if brightness <= 0.0:
		return 0.0
	for i in range(1, VEIL_BRIGHTNESS.size()):
		if brightness <= VEIL_BRIGHTNESS[i]:
			var t := inverse_lerp(VEIL_BRIGHTNESS[i - 1], VEIL_BRIGHTNESS[i], brightness)
			return lerpf(VEIL_ALPHA[i - 1], VEIL_ALPHA[i], t)
	return VEIL_ALPHA[-1]
