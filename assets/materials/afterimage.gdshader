shader_type canvas_item;
// Huella de la puerta tras el cruce: una postimagen oscura sobre el blanco.
// Se dibuja en pantalla completa, de modo que sigue a la mirada.
// Con shape = 1 tiene la forma del vano; al bajar a 0 pierde las esquinas,
// se ablanda y se encoge hasta ser una mancha redonda (el camino inverso del
// punto que se hizo puerta).

// Opacidad del oscurecimiento (0 = invisible). Pensada para valores muy bajos.
uniform float darkness : hint_range(0.0, 1.0) = 0.0;
// 1 = puerta, 0 = mancha redonda.
uniform float shape : hint_range(0.0, 1.0) = 1.0;
// Alto de la puerta en fracción del alto de la pantalla; el ancho sigue la proporción del vano.
uniform float door_height = 0.36;
uniform float door_aspect = 0.615;
// Radio de la mancha final, en fracción del alto de la pantalla.
uniform float blob_radius = 0.07;
// Suavidad del borde: nítido como puerta, difuso como mancha.
uniform vec2 softness_range = vec2(0.09, 0.006);

void fragment() {
	vec2 screen = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 p = (UV - 0.5) * vec2(screen.x / screen.y, 1.0);
	vec2 door_half = vec2(door_height * door_aspect, door_height) * 0.5;
	vec2 half_size = mix(vec2(blob_radius), door_half, shape);
	float corner = mix(blob_radius, 0.0, shape);
	vec2 q = abs(p) - half_size + corner;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - corner;
	float soft = mix(softness_range.x, softness_range.y, shape);
	float mask = 1.0 - smoothstep(-soft, soft, d);
	COLOR = vec4(0.0, 0.0, 0.0, darkness * mask);
}
