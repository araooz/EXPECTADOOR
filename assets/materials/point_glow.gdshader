shader_type spatial;
// Halo esférico del punto de luz lejano: un billboard con caída radial suave.
// Se desvanece a medida que el punto toma forma de puerta.
// Sin prueba de profundidad: el billboard es mayor que el vano y, al girar la
// vista, atravesaría el suelo y el muro (negros, invisibles), que recortarían
// el halo con bordes rectos. Entre el espectador y la puerta no hay nada que
// deba ocultarlo.
render_mode unshaded, blend_add, cull_disabled, shadows_disabled, depth_draw_never, depth_test_disabled;

uniform float strength : hint_range(0.0, 4.0) = 1.0;
// Cuanto mayor, más concentrado el halo hacia el centro.
uniform float falloff = 9.0;

void vertex() {
	// Siempre de cara a la cámara.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float glow = exp(-r * r * falloff) * (1.0 - smoothstep(0.85, 1.0, r));
	ALBEDO = vec3(glow * strength);
}
