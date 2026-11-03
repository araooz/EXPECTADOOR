# EXPECTADOOR

Experiencia interactiva en primera persona, desarrollada en Godot.

## Concepto

*EXPECTADOOR* trata sobre la **expectativa incumplida**: la distancia entre el futuro
que se imagina durante la espera y lo que finalmente se encuentra.

Todo comienza en negro absoluto y en silencio. Unos segundos después aparece, muy
lejos, un punto de luz, y empieza a sonar la música, apenas audible. Al avanzar, la
música crece y se aclara, y el punto se transforma poco a poco en la forma de una
puerta: un vano de luz blanca pura que proyecta su haz sobre el suelo. La puerta no se
abre; se atraviesa. Al cruzarla todo queda blanco y la música salta a su minuto 1:43: tras toda la
intensidad acumulada, un pasaje más apagado, casi triste. Al llegar a 2:15 se apaga y
ya no ocurre nada más.

La obra no explica su significado. No hay meta, recompensa, texto final ni pantalla de
victoria. La aplicación sigue en marcha y el espectador puede permanecer en ese blanco
todo lo que quiera.

| Fase | Qué ocurre |
|---|---|
| **DARKNESS** | 4 s de negro total y silencio. |
| **PROMISE** | Aparece un punto de luz a 76 m; la música entra muy tenue, lejana (filtrada). |
| **APPROACH** | La música crece de −30 dB a −2 dB y se abre su filtro. A partir de 55 m de la puerta, el punto se estira hasta tomar forma de puerta (completa a 14 m). El brillo en el suelo empieza a notarse a 32 m, de forma casi imperceptible, y alcanza su plenitud a 8 m. |
| **THRESHOLD** | En los últimos 3 m, un resplandor blanco empieza a cubrir la pantalla. |
| **ABSENCE** | Al cruzar, la pantalla queda en blanco puro y no vuelve a cambiar. En ese instante la música salta a 1:43, a plena intensidad y sin filtro. Suena hasta 2:15, se desvanece en el último segundo y queda el silencio. |

Esta versión incorpora la retroalimentación de la profesora: inicio en negro y sin
música, aparición de un punto esférico lejano, música que se intensifica con la
cercanía, puerta que toma forma, más velocidad y final en blanco.

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
- **Pasillo de 12 m de ancho**, solo perceptible por sus colisiones.
- **El blanco final** lo garantiza un velo de interfaz completamente blanco.

## Velocidad de movimiento: cómo cambiarla

La velocidad está en la propiedad **`walk_speed`** del jugador, en metros por segundo.
Ahora vale **3,2 m/s** (antes 1,6); el recorrido hasta la puerta dura unos 25 s.

**En el editor (recomendado):**
1. Abre `scenes/player.tscn` (o `scenes/main.tscn` y selecciona el nodo `Player`).
2. En el **Inspector**, grupo **Movimiento**, cambia **Walk Speed**.
3. En el mismo grupo están **Acceleration** (3,5) y **Deceleration** (5,0), que
   controlan lo rápido que arranca y se detiene. Si subes mucho la velocidad, conviene
   subirlas también.

**En el código:** `scripts/player_controller.gd`, línea 10:

```gdscript
@export var walk_speed: float = 3.2
```

Si la cambias en el Inspector de `main.tscn`, solo afecta a esa escena. Si la cambias
en el script, cambia el valor por defecto en todas.

## Requisitos técnicos

- **Godot 4.7.2** (probado con `4.7.2.stable.nixpkgs`). Debería funcionar en
  Godot 4.4 o posterior, pero solo se ha probado en 4.7.2.
- **Renderizador Forward+**, configurado explícitamente en `project.godot`
  (`renderer/rendering_method="forward_plus"`). La prueba verifica que es el método
  activo en ejecución.
- Física Jolt. Sin dependencias externas.
- Resolución inicial de 1280 × 720, que se adapta a otras (`canvas_items` / `expand`).

## Abrir y ejecutar

1. En Godot 4.x: **Importar** y elegir `project.godot`.
2. **Ejecutar proyecto** (F5). La escena principal es `res://scenes/main.tscn`.

Desde la terminal: `godot --path .` (o `godot -e --path .` para abrir el editor).

## Controles

| Tecla | Acción |
|---|---|
| `W` / `↑` | Avanzar |
| `S` / `↓` | Retroceder |
| Ratón | Mirar en cualquier dirección |
| `Esc` | Liberar o volver a capturar el cursor (no cierra la aplicación) |
| Clic | Volver a capturar el cursor |

En el pasillo, el movimiento sigue el eje del recorrido y la mirada está limitada a
±35° en horizontal y ±20° en vertical. Tras cruzar la puerta se camina hacia donde se
mira. No hay salto, carrera ni avance automático. Para salir, se cierra la ventana.

## Estructura

```
project.godot
scenes/
  main.tscn          Entorno, pasillo, puerta, espacio posterior, jugador, música, HUD
  corridor.tscn      Pasillo de 77 × 12 m, sin luces; paredes y techo en la capa de render 2
  door.tscn          Luz de la puerta (shader), halo del punto, foco del haz y halo del suelo
  final_room.tscn    Espacio tras la puerta: solo colisiones y volumen de detección
  player.tscn        CharacterBody3D, cabeza y cámara
  hud.tscn           Indicaciones de control y velo (resplandor y blanco final)
scripts/
  experience_controller.gd   Fases, anticipación, forma de la puerta y resplandor
  player_controller.gd       Movimiento guiado y mirada limitada (velocidad)
  door_controller.gd         Aparición, forma e intensidad de la luz de la puerta
  audio_controller.gd        Música adaptativa: cercanía, bucle al compás y salto al cruzar
  final_room.gd              Señales de entrada y salida del espacio tras la puerta
  hud.gd                     Indicaciones, resplandor y blanco final
assets/
  audio/goodbye_to_a_world.mp3   Música (ver "Música y derechos")
  audio/default_bus_layout.tres  Bus "Ambience" con filtro paso bajo
  materials/                     Shaders y materiales de la puerta y del pasillo
  sugerencias/                   Imagen de referencia (no la usa la obra)
tests/autotest.gd    Recorrido automatizado con comprobaciones
```

**Comunicación entre componentes.** `ExperienceController` hace aparecer la luz tras
`darkness_duration` y llama a `DoorController.reveal()` y `AudioController.start()`.
En cada frame mide la distancia a la puerta y, a partir de ella, ajusta:
- la anticipación: `set_anticipation()` en la puerta y en el audio;
- la forma: `DoorController.set_shape()`;
- la luz del suelo: `DoorController.set_floor_light()`;
- el resplandor: `Hud.set_glare()`.

Cuando `FinalRoom` emite `player_entered` (el espectador cruza el plano de la puerta),
llama a `Hud.play_crossing()`, `DoorController.extinguish()` y
`AudioController.play_crossing()`. Las tres acciones son irreversibles.

## Música adaptativa

La música sigue tres reglas:

- **Guiada por la distancia.** Antes de cruzar, el volumen (−30 → −2 dB) y el filtro
  paso bajo (500 → 20 000 Hz) dependen de la cercanía a la puerta.
- **Separada por fases.** Antes del cruce suena la canción desde 0:00. El fragmento
  de 1:43 a 2:15 queda reservado para el cruce.
- **Bucle cuantizado al compás.** La canción va a 96 BPM, así que un compás de 4
  tiempos dura 2,5 s. Si el espectador tarda en llegar, al terminar el compás
  anterior a 1:43 (en 1:42,5) la canción vuelve a 0:00.

Los tiempos se ajustan en el nodo `AudioController` de `main.tscn`, en los grupos
**Tempo** y **Fragmentos** del Inspector: `crossing_cue_time` (1:43 = 103 s),
`song_end_time` (2:15 = 135 s), `approach_loop_start` y `first_downbeat`.

## Música y derechos

La música es **"Goodbye To A World" de Porter Robinson**
(`assets/audio/goodbye_to_a_world.mp3`, importada en bucle). Está protegida por
derechos de autor y no tiene licencia libre. Usarla en una entrega académica en clase
suele estar aceptado, pero **publicar o distribuir la obra con esta canción requeriría
permiso del titular**. Para sustituirla, basta con reemplazar el `stream` del nodo
`AudioController/Music` en `main.tscn`.

## Parámetros de ritmo

Todos se editan en el Inspector:

- **Main** (ExperienceController):
  - `darkness_duration` (4 s): segundos de negro antes de que aparezca el punto;
  - `shape_start_distance` (55 m) y `shape_complete_distance` (14 m): dónde empieza y
    termina la transformación del punto en puerta;
  - `floor_light_start_distance` (32 m) y `floor_light_full_distance` (8 m): dónde
    empieza a notarse el brillo en el suelo y dónde alcanza su plenitud;
  - `glare_distance` (3 m): distancia a la que empieza el resplandor;
  - `anticipation_response`: lo rápido que luz y sonido siguen a la posición.
- **AudioController**: `music_volume_range_db` (−30 → −2 dB), `intro_fade_duration`,
  `lowpass_cutoff_range_hz`.
- **Door**: `reveal_duration`, energías del haz y del halo, `point_glow_strength`.
- **Hud**: `crossing_white_duration` (0,4 s): paso al blanco al cruzar.
- **Player**: `walk_speed` (ver arriba).

## Pruebas realizadas

```sh
godot --path . --script res://tests/autotest.gd -- --shots=/ruta/capturas   # con ventana
godot --headless --path . --script res://tests/autotest.gd                  # sin ventana
```

Durante la prueba se desvinculan las teclas físicas de las acciones, para que el
teclado del escritorio no interfiera con el recorrido simulado.

Resultado (Godot 4.7.2, Linux, NVIDIA RTX 3050, Vulkan): **todas las comprobaciones
superadas, con ventana y en headless.**

- Forward+ activo. La canción está cargada y en bucle. La única fuente de luz es la
  puerta.
- Durante los primeros segundos: sin luz y sin música. Se midió el brillo de la
  captura: máximo 0,000 (negro puro).
- A los 4 s aparece el punto (forma 0,00) y empieza la música. Posición inicial
  correcta, a 75,8 m de la puerta.
- Colisiones: el muro del inicio y las paredes laterales (a ±6 m) detienen al jugador.
  La mirada gira libremente (vertical limitada a ±89°).
- La música crece de forma monótona de −29,9 a −5,1 dB, con un cambio máximo de
  1,6 dB/s. Al retroceder, disminuye.
- El punto toma forma de puerta de manera progresiva (0 → 1). Mientras solo se ve el
  punto, el suelo no recibe luz.
- El resplandor solo aparece en los últimos metros.
- La puerta se atraviesa sin abrirse. Al cruzar queda blanco puro: se midió la captura
  y el brillo mínimo es 1,000.
- Antes de cruzar, la canción no llega a 1:43; al final del compás de 1:42,5 vuelve al
  inicio.
- Al cruzar suena el minuto 1:43 a plena intensidad y sin filtro. A las 2:15 se
  desvanece y queda el silencio.
- El blanco y el silencio persisten al moverse y al volver al pasillo.

**Revisión visual.** Se compararon capturas reales con la imagen de referencia y se
corrigieron:
- el punto lejano, que se veía casi invisible (se añadió el halo esférico);
- el halo del punto, que el suelo y el muro recortaban con bordes rectos según hacia
  dónde se mirara;
- el halo de la puerta, que iluminaba el muro del fondo de gris;
- un velo de resplandor demasiado temprano, que agrisaba la imagen.

**No verificado:**
- la escucha real por altavoces;
- el manejo con teclado y ratón físicos por una persona;
- la respuesta emocional, que requiere pruebas con público.

## Limitaciones conocidas

- Al cerrar, Godot 4.7.2 escribe en consola avisos ("ObjectDB instances were leaked",
  "resources still in use") sobre el audio que estaba sonando. Es un comportamiento del
  motor: se reproduce con un proyecto vacío que solo contiene un `AudioStreamPlayer`
  reproduciendo, y no afecta a la obra.
- La música tiene derechos de autor (ver arriba). Si se exporta, conviene excluir
  `tests/` y `assets/sugerencias/`.
- No hay preset de exportación ni menú para salir (de forma deliberada).
