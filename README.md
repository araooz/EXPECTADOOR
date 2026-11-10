# EXPECTADOOR

Experiencia interactiva en primera persona, desarrollada en Godot.

## Concepto

*EXPECTADOOR* trata sobre la **expectativa incumplida**: la distancia entre el futuro
que se imagina durante la espera y lo que finalmente se encuentra.

El espectador no camina: solo puede girar la cabeza, en cualquier dirección. Es
llevado, sin poder detenerse ni volver atrás, como quien espera algo que no controla.

Todo comienza en negro absoluto y en silencio. A los 2,5 s aparece, muy lejos, un punto
de luz, y empieza a sonar la música, apenas audible. Mientras el espectador avanza, la
música crece y se aclara, y el punto se transforma poco a poco en la forma de una
puerta: un vano de luz blanca pura que proyecta su haz sobre el suelo. La puerta no se
abre; se atraviesa. Al cruzarla, en pleno clímax de la canción, la música se corta en
seco y todo queda blanco y en silencio. Ya no ocurre nada más.

La obra no explica su significado. No hay meta, recompensa, texto final ni pantalla de
victoria. La aplicación sigue en marcha y el espectador puede permanecer en ese blanco
todo lo que quiera.

## Duración exacta: 1:48

| Tiempo | Qué ocurre |
|---|---|
| 0:00,0 – 0:02,5 | Negro y silencio. |
| 0:02,5 | Aparece el punto; la canción entra desde su 0:00, muy tenue. |
| 0:02,5 – 1:48,0 | Avance automático hacia la puerta (75,8 m). |
| 1:48,0 | Cruce de la puerta. La canción (en su 1:45,5) se corta a silencio total y la pantalla queda blanca. |

La duración total es `silence_duration` (2,5 s, en `Main`) + `cut_time` (105,5 s, en
`AudioController`). Para alargar o acortar la experiencia basta con cambiar `cut_time`:
el recorrido se recalcula solo. El clímax de la canción se sostiene hasta ~1:44,7; en
1:45,5 ya está en su caída (~10 dB por debajo del pico), así que el corte llega cuando
la música empieza a apagarse.

**Sincronía.** Mientras suena la canción, su posición de reproducción es el reloj de
la obra: la posición del espectador se calcula a partir de ella. Así el cruce y el
corte ocurren en el mismo instante aunque haya tirones de imagen.

**Avance.** Acelera suavemente durante 4 s (`travel_ease_in`) y luego sigue a velocidad
constante (~0,73 m/s) hasta cruzar la puerta sin frenar.

| Fase | Qué ocurre |
|---|---|
| **DARKNESS** | 2,5 s de negro total y silencio. |
| **PROMISE** | Aparece un punto de luz a 76 m; la música entra muy tenue, lejana (filtrada). |
| **APPROACH** | El espectador es llevado hacia la puerta. La música crece de −30 dB a −2 dB y se abre su filtro. A partir de 55 m de la puerta, el punto se estira hasta tomar forma de puerta (completa a 14 m). El brillo en el suelo empieza a notarse a 32 m, de forma casi imperceptible, y alcanza su plenitud a 8 m. |
| **THRESHOLD** | En los últimos 3 m, un resplandor blanco empieza a cubrir la pantalla. |
| **ABSENCE** | Al cruzar (1:48), la música se corta a silencio total y la pantalla queda en blanco puro. Nada vuelve a cambiar. |

Esta versión incorpora la retroalimentación de la profesora: inicio en negro y sin
música, aparición de un punto esférico lejano, música que se intensifica con la
cercanía, puerta que toma forma y final en blanco. Además, el espectador ya no se
desplaza por sí mismo y la experiencia dura exactamente 1:48.

La referencia visual de la puerta es `assets/sugerencias/puerta blanca fondo negro.jpg`.

### Cómo se consigue la imagen

- **Una sola fuente de luz.** No hay luz ambiente, el fondo es negro y todas las luces
  de la escena pertenecen a la puerta (la prueba automatizada lo verifica).
- **Del punto a la puerta.** El shader `door_light.gdshader` dibuja un rectángulo de
  esquinas redondeadas. Su radio de esquina pasa del radio del punto (un círculo) a
  cero (el rectángulo del vano). Un billboard (`point_glow.gdshader`) añade el halo
  esférico del punto lejano y se desvanece cuando la puerta toma forma. Ese halo se
  dibuja sin prueba de profundidad: así el suelo y el muro, aunque negros e
  invisibles, no lo recortan al girar la vista.
- **El haz en el suelo** viene de un foco situado 12 m detrás del muro, por encima del
  dintel. El vano recorta su luz, que cae como un trapecio estrecho y se apaga antes de
  alcanzar las paredes. Su intensidad depende de la distancia: mientras solo se ve el
  punto, el suelo está negro. Paredes y techo están en otra capa de render que ninguna luz
  ilumina, así que la luz nunca "choca" con ellas: el pasillo es negro.
- **Pasillo de 12 m de ancho**, invisible: sirve solo para recibir el haz en el suelo.
- **El blanco final** lo garantiza un velo de interfaz completamente blanco.

## Requisitos técnicos

- **Godot 4.7.2** (probado con `4.7.2.stable.nixpkgs`). Debería funcionar en
  Godot 4.4 o posterior, pero solo se ha probado en 4.7.2.
- **Renderizador Forward+**, configurado explícitamente en `project.godot`
  (`renderer/rendering_method="forward_plus"`). La prueba verifica que es el método
  activo en ejecución.
- Sin dependencias externas.
- Resolución inicial de 1280 × 720, que se adapta a otras (`canvas_items` / `expand`).

## Abrir y ejecutar

1. En Godot 4.x: **Importar** y elegir `project.godot`.
2. **Ejecutar proyecto** (F5). La escena principal es `res://scenes/main.tscn`.

Desde la terminal: `godot --path .` (o `godot -e --path .` para abrir el editor).

## Controles

| Tecla | Acción |
|---|---|
| Ratón | Mirar en cualquier dirección (vertical limitada a ±89°) |
| `Esc` | Liberar o volver a capturar el cursor (no cierra la aplicación) |
| Clic | Volver a capturar el cursor |

No hay ningún control de desplazamiento. Para salir, se cierra la ventana.

## Estructura

```
project.godot
scenes/
  main.tscn          Entorno, pasillo, puerta, espacio posterior, jugador, música, HUD
  corridor.tscn      Pasillo de 77 × 12 m, sin luces; paredes y techo en la capa de render 2
  door.tscn          Luz de la puerta (shader), halo del punto, foco del haz y halo del suelo
  player.tscn        Cabeza y cámara (sin cuerpo físico)
  hud.tscn           Indicaciones de control y velo (resplandor y blanco final)
scripts/
  experience_controller.gd   Línea de tiempo, avance automático, fases, forma de la puerta y resplandor
  player_controller.gd       Solo la mirada
  door_controller.gd         Aparición, forma e intensidad de la luz de la puerta
  audio_controller.gd        Música: crece con la cercanía y se corta al cruzar
  hud.gd                     Indicaciones, resplandor y blanco final
assets/
  audio/goodbye_to_a_world.mp3   Música (ver "Música y derechos")
  audio/default_bus_layout.tres  Bus "Ambience" con filtro paso bajo
  materials/                     Shaders y materiales de la puerta y del pasillo
  sugerencias/                   Imagen de referencia (no la usa la obra)
tests/autotest.gd    Recorrido automatizado con comprobaciones
```

**Comunicación entre componentes.** `ExperienceController` lleva el reloj. A los
`silence_duration` segundos llama a `DoorController.reveal()` y `AudioController.start()`;
desde ese momento el reloj es la posición de la canción. En cada frame coloca al
espectador según la línea de tiempo, mide su distancia a la puerta y, a partir de ella,
ajusta:
- la anticipación: `set_anticipation()` en la puerta y en el audio;
- la forma: `DoorController.set_shape()`;
- la luz del suelo: `DoorController.set_floor_light()`;
- el resplandor: `Hud.set_glare()`.

Al llegar a la duración total llama a `Hud.play_crossing()`, `DoorController.extinguish()`
y `AudioController.cut()`. Las tres acciones son irreversibles.

## Música

- **Guiada por la distancia.** El volumen (−30 → −2 dB) y el filtro paso bajo
  (500 → 20 000 Hz) dependen de la cercanía a la puerta.
- **Corte seco.** En `cut_time` (1:45,5) la música se apaga en 20 ms
  (`cut_ramp_duration`, solo para evitar un chasquido) y queda el silencio.

## Música y derechos

La música es **"Goodbye To A World" de Porter Robinson**
(`assets/audio/goodbye_to_a_world.mp3`, ). Está protegida por
derechos de autor y no tiene licencia libre. Usarla en una entrega académica en clase
suele estar aceptado, pero **publicar o distribuir la obra con esta canción requeriría
permiso del titular**. Para sustituirla, basta con reemplazar el `stream` del nodo
`AudioController/Music` en `main.tscn`.

## Parámetros de ritmo

Todos se editan en el Inspector:

- **Main** (ExperienceController):
  - `silence_duration` (2,5 s): segundos de negro y silencio antes del punto y la música;
  - `travel_ease_in` (4 s): arranque suave del avance;
  - `shape_start_distance` (55 m) y `shape_complete_distance` (14 m): dónde empieza y
    termina la transformación del punto en puerta;
  - `floor_light_start_distance` (32 m) y `floor_light_full_distance` (8 m): dónde
    empieza a notarse el brillo en el suelo y dónde alcanza su plenitud;
  - `glare_distance` (3 m): distancia a la que empieza el resplandor;
  - `anticipation_response`: lo rápido que luz y sonido siguen a la posición.
- **AudioController**: `cut_time` (105,5 s), `music_volume_range_db` (−30 → −2 dB),
  `intro_fade_duration`, `lowpass_cutoff_range_hz`.
- **Door**: `reveal_duration`, energías del haz y del halo, `point_glow_strength`.
- **Hud**: `crossing_white_duration` (0,4 s): paso al blanco al cruzar.
- **Player**: `mouse_sensitivity`, `look_smoothing`.

## Pruebas realizadas

```sh
godot --path . --script res://tests/autotest.gd -- --shots=/ruta/capturas   # con ventana
godot --headless --path . --script res://tests/autotest.gd                  # sin ventana
```

La prueba recorre la obra completa en tiempo real (~2 min).

Resultado (Godot 4.7.2, Linux, NVIDIA RTX 3050, Vulkan): **todas las comprobaciones
superadas, con ventana y en headless.**

- Forward+ activo. La única fuente de luz es la puerta. No existen acciones de
  desplazamiento y el espectador no es un cuerpo físico.
- 0–2,5 s: sin luz y sin música; brillo máximo de la captura 0,000 (negro puro).
- A los 2,5 s aparece el punto (forma 0,00) a 75,8 m y la canción empieza desde 0:00.
- La mirada gira libremente (−180°); girar o pulsar teclas no altera la posición.
- El avance es continuo; la música crece de forma monótona de −29,9 a −4,0 dB (máx.
  0,7 dB cada 2 s); el punto toma forma de puerta; con solo el punto visible, el suelo
  no recibe luz; el resplandor aparece en los últimos metros.
- Cruce a 108,00 s en la línea de tiempo y **107,91 s de reloj real** (con ventana),
  en el plano de la puerta. La canción se corta en 105,50 s. Silencio total inmediato y
  blanco puro (brillo mínimo 1,000), que persisten.
- En headless, el driver de audio simulado avanza ~0,7 % más lento que el reloj real
  (cruce ~0,8 s más tarde según el reloj); con audio real el desfase es de ~0,1 s.
- Si la imagen se ralentiza (por ejemplo, con la ventana oculta, a ~1 FPS), el cruce y
  el corte siguen ocurriendo en el momento correcto, porque el reloj es la canción. Por
  eso la prueba mide el tiempo con el reloj del sistema y no sumando los `delta`.

**Revisión visual.** Se compararon capturas reales con la imagen de referencia y se
corrigieron:
- el punto lejano, que se veía casi invisible (se añadió el halo esférico);
- el halo del punto, que el suelo y el muro recortaban con bordes rectos según hacia
  dónde se mirara;
- el halo de la puerta, que iluminaba el muro del fondo de gris;
- un velo de resplandor demasiado temprano, que agrisaba la imagen.

**No verificado:**
- la escucha real por altavoces;
- el manejo con ratón físico por una persona;
- la respuesta emocional, que requiere pruebas con público.

## Limitaciones conocidas

- Al cerrar, Godot 4.7.2 escribe en consola avisos ("ObjectDB instances were leaked",
  "resources still in use") sobre el audio que estaba sonando. Es un comportamiento del
  motor: se reproduce con un proyecto vacío que solo contiene un `AudioStreamPlayer`
  reproduciendo, y no afecta a la obra.
- La música tiene derechos de autor (ver arriba). Si se exporta, conviene excluir
  `tests/` y `assets/sugerencias/`.
- No hay preset de exportación ni menú para salir (de forma deliberada).
