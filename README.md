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
abre; se atraviesa. Al cruzarla, justo cuando el clímax de la canción empieza a caer,
todo queda blanco.

La música no se corta: se aleja. En unos segundos pierde sus agudos, se llena de
reverberación y baja hasta volverse el eco ausente, como si siguiera sonando en otra
habitación. Lo que se oye es lo que la canción traía después del clímax, un pasaje más
apagado, casi triste: lo que habría venido. Al mismo tiempo, y con la misma suavidad,
aparece en el blanco la huella de la puerta, una silueta oscura apenas perceptible: su
postimagen, la que el propio ojo tiende a producir tras mirar una luz mucho tiempo. La
huella sigue a la mirada. Eco y huella se sostienen y luego se desvanecen juntos; la
huella, por el camino inverso al del comienzo: de puerta a mancha redonda, y de ahí a
nada. Después, blanco y silencio para siempre.

La obra no explica su significado. No hay meta, recompensa, texto final ni pantalla de
victoria. La aplicación sigue en marcha y el espectador puede permanecer en ese blanco
todo lo que quiera.

## Duración exacta: 1:48

| Tiempo | Qué ocurre |
|---|---|
| 0:00,0 – 0:02,5 | Negro y silencio. |
| 0:02,5 | Aparece el punto; la canción entra desde su 0:00, muy tenue. |
| 0:02,5 – 1:48,0 | Avance automático hacia la puerta (75,8 m). |
| 1:48,0 | Cruce de la puerta (canción en 1:45,5). Pantalla blanca; la canción empieza a alejarse hacia el eco y aparece la huella. |
| 2:13,0 | Eco y huella terminan de desvanecerse. Blanco y silencio definitivos. |

La duración hasta el cruce es `silence_duration` (2,5 s, en `Main`) + `crossing_time`
(105,5 s, en `AudioController`). Para cambiarla basta con modificar `crossing_time`: el
recorrido se recalcula solo. Lo que sigue al cruce dura 25 s (ver abajo). El clímax de
la canción se sostiene hasta ~1:44,7; en 1:45,5 ya está cayendo, y desde ~1:45,8 entra
el pasaje tranquilo, que se mantiene parejo hasta pasado 2:15.

**Sincronía.** Mientras suena la canción, su posición de reproducción es el reloj de
la obra: la posición del espectador se calcula a partir de ella. Así el cruce cae en el
punto exacto de la canción aunque haya tirones de imagen.

**Avance.** Acelera suavemente durante 4 s (`travel_ease_in`) y luego sigue a velocidad
constante (~0,73 m/s) hasta cruzar la puerta sin frenar.

| Fase | Qué ocurre |
|---|---|
| **DARKNESS** | 2,5 s de negro total y silencio. |
| **PROMISE** | Aparece un punto de luz a 76 m; la música entra muy tenue, lejana (filtrada). |
| **APPROACH** | El espectador es llevado hacia la puerta. La música crece de −30 dB a −2 dB y se abre su filtro. A partir de 55 m de la puerta, el punto se estira hasta tomar forma de puerta (completa a 14 m). El brillo en el suelo empieza a notarse a 32 m, de forma casi imperceptible, y alcanza su plenitud a 8 m. |
| **THRESHOLD** | En los últimos 3 m, un resplandor blanco empieza a cubrir la pantalla. |
| **ABSENCE** | Al cruzar (1:48), la pantalla queda en blanco puro; la canción se aleja hasta ser el eco ausente y aparece la huella (ver abajo). Al terminar, nada vuelve a cambiar. |

## Después del cruce: la huella y el eco

| Tras el cruce | Imagen | Sonido |
|---|---|---|
| 0 – 5 s | Blanco; la huella de la puerta aparece poco a poco | La canción se aleja: pierde agudos (→ 450 Hz), gana reverberación y baja (→ −30 dB) |
| 5 – 17 s | La huella se mantiene (3,5 % más oscura que el blanco) | **Eco ausente**: la canción sigue, lejana, como desde otra habitación |
| 17 – 25 s | La huella pierde las esquinas, se vuelve una mancha redonda y desaparece | El eco se desvanece |
| 25 s en adelante | Blanco, para siempre | Silencio, para siempre |

Transición, sostén y desvanecimiento son los mismos para la imagen y el sonido
(`aftermath_transition`, `aftermath_hold` y `aftermath_fade`, en `Main`), y usan la
misma curva: huella y eco avanzan juntos.

- **La huella** (`assets/materials/afterimage.gdshader`, nodo `Hud/Trace`) se dibuja en
  pantalla, así que sigue a la mirada: no se puede dejar de verla girando. Es oscura
  sobre claro porque es la inversión de la puerta luminosa, como una postimagen real.
  Al disolverse hace el camino inverso del punto que se hizo puerta.
- **El eco ausente** no es otra pista: es la misma canción, que nunca se interrumpe.
  En el bus `Ambience`, el filtro paso bajo que se abrió durante la aproximación se
  vuelve a cerrar y una reverberación (sin efecto durante el recorrido) entra en la
  mezcla. Por eso la transición no tiene costuras.
- Las dos cosas ocurren una sola vez.

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

No hay ningún control de desplazamiento ni ninguna indicación en pantalla. Para salir,
se cierra la ventana.

**Solo para desarrollo** (nodo `DevSpeed` en `main.tscn`; se desactiva solo en una
exportación release):

| Tecla | Acción |
|---|---|
| `1` | Alterna velocidad x2 |
| `2` | Alterna velocidad x4 |
| `3` | Alterna velocidad x8 |
| `4` | Alterna velocidad x16 |

Pulsar la misma tecla otra vez vuelve a x1. Se aceleran la canción (que sube de tono) y,
con ella, el recorrido, además de la aparición de la luz, la huella y el eco. Para
quitarlo del todo, se borra el nodo `DevSpeed` de `main.tscn`.

## Estructura

```
project.godot
scenes/
  main.tscn          Entorno, pasillo, puerta, espacio posterior, jugador, música, HUD
  corridor.tscn      Pasillo de 77 × 12 m, sin luces; paredes y techo en la capa de render 2
  door.tscn          Luz de la puerta (shader), halo del punto, foco del haz y halo del suelo
  player.tscn        Cabeza y cámara (sin cuerpo físico)
  hud.tscn           Velo (resplandor y blanco final) y huella; sin texto en pantalla
scripts/
  experience_controller.gd   Línea de tiempo, avance automático, fases, forma de la puerta y resplandor
  player_controller.gd       Solo la mirada
  door_controller.gd         Aparición, forma e intensidad de la luz de la puerta
  audio_controller.gd        Música: crece con la cercanía y al cruzar se aleja hasta ser el eco
  hud.gd                     Resplandor, blanco final y huella
  dev_speed.gd               Solo desarrollo: teclas 1–4 para acelerar x2 / x4 / x8 / x16
assets/
  audio/goodbye_to_a_world.mp3   Música (ver "Música y derechos")
  audio/default_bus_layout.tres  Bus "Ambience": paso bajo y reverberación
  materials/                     Shaders y materiales de la puerta, el pasillo y la huella
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

Al llegar a la duración total llama a `Hud.play_crossing()`, `Hud.play_trace()`,
`DoorController.extinguish()` y `AudioController.play_echo()`, pasando a la huella y al
eco los mismos tiempos. Todas las acciones son irreversibles.

## Música

- **Guiada por la distancia.** El volumen (−30 → −2 dB) y el filtro paso bajo
  (500 → 20 000 Hz) dependen de la cercanía a la puerta.
- **Alejamiento al cruzar.** Desde `crossing_time` (1:45,5) la canción sigue sonando,
  pero se transforma en el eco ausente y después se desvanece (ver *Después del cruce*).

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
- **AudioController**: `crossing_time` (105,5 s), `music_volume_range_db` (−30 → −2 dB),
  `intro_fade_duration`, `lowpass_cutoff_range_hz`.
- **Door**: `reveal_duration`, energías del haz y del halo, `point_glow_strength`.
- **Main**, grupo *Después del cruce*: `aftermath_transition` (5 s), `aftermath_hold`
  (12 s) y `aftermath_fade` (8 s), compartidos por la huella y el eco.
- **AudioController**, grupo *Eco ausente*: `echo_volume_db` (−30 dB), `echo_lowpass_hz`
  (450 Hz), `echo_reverb_wet` (0,6) y `echo_reverb_dry` (0,5). El carácter de la sala
  (tamaño, amortiguación) se ajusta en la reverberación del bus `Ambience`.
- **Hud**: `crossing_white_duration` (0,4 s): paso al blanco al cruzar. Grupo *Huella*:
  `trace_peak_darkness` (0,035).
  Tamaño y suavidad de la huella: parámetros del material de `Hud/Trace`.
- **Player**: `mouse_sensitivity`, `look_smoothing`.

## Pruebas realizadas

```sh
godot --path . --script res://tests/autotest.gd -- --shots=/ruta/capturas   # con ventana
godot --headless --path . --script res://tests/autotest.gd                  # sin ventana
godot --path . --script res://tests/autotest.gd -- --solo-final             # cruce y después (~35 s)
```

La prueba recorre la obra completa en tiempo real (~2,5 min). Con `--solo-final`
adelanta la canción a 4 s del cruce (la obra la sigue como reloj) y comprueba solo el
cruce, la huella y el eco.

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
  en el plano de la puerta, con la canción en 105,50 s.
- En headless, el driver de audio simulado avanza ~0,7 % más lento que el reloj real
  (cruce ~0,8 s más tarde según el reloj); con audio real el desfase es de ~0,1 s.
- Si la imagen se ralentiza (por ejemplo, con la ventana oculta, a ~1 FPS), el cruce
  sigue ocurriendo en el momento correcto, porque el reloj es la canción. Por
  eso la prueba mide el tiempo con el reloj del sistema y no sumando los `delta`.
- Cruce, huella y eco (`--solo-final`, con ventana): el cruce cae en 105,50 s de la
  canción; la pantalla queda blanca y la canción sigue sin saltos; la huella empieza a
  aparecer de inmediato; a mitad de la transición, huella y eco van a la par (0,50 y
  0,50) y el filtro está en ~3000 Hz; a los 6 s el eco está a −30 dB, 450 Hz y
  reverberación 0,60, y la huella tiene forma de puerta (centro de la imagen a 0,965,
  esquinas a 1,000) y sigue en el centro al girar la mirada; a los 21 s la huella está
  perdiendo la forma mientras el eco baja; a los 25,5 s ambos han terminado; después,
  blanco puro (mín. 1,000) y silencio definitivos.

**Revisión visual.** Se compararon capturas reales con la imagen de referencia y se
corrigieron:
- el punto lejano, que se veía casi invisible (se añadió el halo esférico);
- el halo del punto, que el suelo y el muro recortaban con bordes rectos según hacia
  dónde se mirara;
- el halo de la puerta, que iluminaba el muro del fondo de gris;
- un velo de resplandor demasiado temprano, que agrisaba la imagen.

**No verificado:**
- la escucha real con los audífonos (en particular, cómo suena la transición, si el
  eco a −30 dB se percibe bien y
  si la huella al 3,5 % se distingue en el visor);
- la suite completa (recorrido + después) de una sola vez: se verificó el recorrido y,
  por separado, el después;
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
- **Todavía no es compatible con VR**: no tiene OpenXR activado ni nodos XR, la mirada
  se controla con el ratón y el velo blanco, el resplandor y la huella se dibujan en
  una capa 2D (`CanvasLayer`), que no aparece en los visores.
