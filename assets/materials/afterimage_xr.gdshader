shader_type spatial;
// La huella de la puerta en VR: la misma forma que afterimage.gdshader, pero en
// un quad pegado a la cámara (sigue a la mirada). Medidas en metros sobre el
// quad, calculadas para que ocupe el mismo ángulo de visión que en pantalla.
render_mode unshaded, blend_mix, cull_disabled, shadows_disabled, depth_draw_never, depth_test_disabled, fog_disabled;

// Oscurecimiento percibido (como en pantalla: 0,035 = 3,5 % más oscuro que el blanco).
uniform float darkness : hint_range(0.0, 1.0) = 0.0;
// 1 = puerta, 0 = mancha redonda.
uniform float shape : hint_range(0.0, 1.0) = 1.0;
uniform vec2 quad_size = vec2(3.0, 3.0);
uniform vec2 door_half_size = vec2(0.45, 0.73);
uniform float blob_radius = 0.28;
uniform vec2 softness_range = vec2(0.36, 0.024);

void fragment() {
	vec2 p = (UV - 0.5) * quad_size;
	vec2 half_size = mix(vec2(blob_radius), door_half_size, shape);
	float corner = mix(blob_radius, 0.0, shape);
	vec2 q = abs(p) - half_size + corner;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - corner;
	float soft = mix(softness_range.x, softness_range.y, shape);
	float mask = 1.0 - smoothstep(-soft, soft, d);
	// La mezcla ocurre en espacio lineal: se convierte el oscurecimiento
	// percibido (sRGB) para que sobre el blanco lineal se vea igual que en pantalla.
	ALBEDO = vec3(0.0);
	ALPHA = (1.0 - pow(1.0 - darkness, 2.2)) * mask;
}
