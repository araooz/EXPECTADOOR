# EXPECTADOOR

Experiencia interactiva en primera persona, desarrollada en Godot.

## Concepto

*EXPECTADOOR* trata sobre la **expectativa incumplida**: la distancia entre el futuro
que se imagina durante la espera y lo que finalmente se encuentra.

El espectador está en la oscuridad total. A lo lejos, a 56 m, brilla una única
puerta: un vano de luz blanca pura, sin marco y sin hoja, que proyecta un haz sobre el
suelo. Es lo único visible. Al avanzar, la puerta crece, la luz se intensifica y el
sonido se vuelve más presente. Ante el umbral, la luz empieza a llenar la mirada. La
puerta no se abre: se atraviesa. Al cruzarla, todo se vuelve blanco y después vuelve
la oscuridad pura, ahora sin puerta, sin luz y sin sonido.

La obra no explica su significado. No hay meta, recompensa, texto final ni pantalla de
victoria. La aplicación sigue en marcha; el espectador puede permanecer en esa
oscuridad todo lo que quiera.

| Fase | Qué ocurre |
|---|---|
| **PROMISE** (la promesa) | Fundido desde negro. Solo se ve la puerta blanca, lejana, y su haz en el suelo. Sonido tenue. |
| **APPROACH** (la aproximación) | La luz y el sonido crecen con la cercanía real del espectador, y responden también si se detiene o retrocede. |
| **THRESHOLD** (el umbral) | En los últimos 3,5 m, un resplandor blanco empieza a cubrir la pantalla. |
| **ABSENCE** (la ausencia) | Al cruzar: blanco total durante 1,2 s, transición a negro en 3 s, la puerta se apaga y el sonido se desvanece en 2,5 s. La oscuridad y el silencio ya no se retiran. |

La referencia visual de la puerta es `assets/sugerencias/puerta blanca fondo negro.jpg`.

### Cómo se consigue la imagen

- **Una sola fuente de luz.** No hay luz ambiente, el fondo es negro y no hay luces en
  el pasillo. Todas las luces de la escena pertenecen a la puerta (la prueba
  automatizada lo verifica).
- **La puerta** es un plano emisivo blanco que ocupa exactamente el vano del muro, sin
  marco ni textura. El halo que la rodea sale del *glow* del entorno.
- **El haz sobre el suelo** lo produce un foco situado detrás del muro, por encima del
  dintel: el vano recorta su luz y el trapecio luminoso cae sobre el suelo, como en la
  referencia. Paredes y techo están en la capa de render 2, que ese foco no ilumina,
  así que el pasillo permanece negro y solo se ve el suelo bajo el haz.
- **Más allá de la puerta** no hay superficies visibles ni luz, solo colisiones para
  que se pueda seguir caminando. Un velo negro garantiza que la imagen sea negro puro.

## Requisitos técnicos

- **Godot 4.7.2** (probado con `4.7.2.stable.nixpkgs`). Debería funcionar en
  Godot 4.4 o posterior, pero solo se ha probado en 4.7.2.
- **Renderizador Forward+**, configurado explícitamente en `project.godot`
  (`renderer/rendering_method="forward_plus"`, característica `"Forward Plus"`). La
  prueba verifica que es el método activo en ejecución.
- Física Jolt (integrada en Godot 4.4 y posteriores). Sin dependencias externas.
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
| Ratón | Mirar (giro limitado) |
| `Esc` | Liberar o volver a capturar el cursor (no cierra la aplicación) |
| Clic | Volver a capturar el cursor |

En el pasillo, el movimiento sigue el eje del recorrido y la mirada está limitada a
±35° en horizontal y ±20° en vertical. Tras cruzar se camina hacia donde se mira
(±140°, ±40°). No hay salto, carrera ni avance automático. Para salir, se cierra la
ventana.

## Estructura

```
project.godot
scenes/
  main.tscn          Entorno (negro, glow), pasillo, puerta, más allá, jugador, audio, HUD
  corridor.tscn      Pasillo de 57 m, sin luces; paredes y techo en la capa de render 2
  door.tscn          Plano de luz blanca, foco del haz (solo capa 1) y halo
  final_room.tscn    Espacio oscuro tras la puerta: solo colisiones y volumen de detección
  player.tscn        CharacterBody3D, cabeza y cámara
  hud.tscn           Fundido inicial, indicaciones y velo del cruce
scripts/
  experience_controller.gd   Fases, anticipación (0 → 1) y resplandor según la distancia
  player_controller.gd       Movimiento guiado y mirada limitada
  door_controller.gd         Intensidad de la luz de la puerta y su extinción
  audio_controller.gd        Mezcla según la cercanía y desvanecimiento definitivo
  final_room.gd              Señales de entrada y salida del espacio tras la puerta
  hud.gd                     Indicaciones, resplandor y paso a la oscuridad
assets/
  audio/             WAV generados y bus "Ambience"
  materials/         Materiales del pasillo y de la puerta
  sugerencias/       Material de referencia (no lo usa la obra)
tests/autotest.gd    Recorrido automatizado con comprobaciones
tools/generate_audio.py   Generador del audio (Godot ignora esta carpeta)
```

**Comunicación entre componentes.** `ExperienceController` mide la distancia a la
puerta sobre el eje del recorrido y, a partir de ella, ajusta:
- la anticipación: `DoorController.set_anticipation()` y `AudioController.set_anticipation()`;
- el resplandor: `Hud.set_glare()`.

Cuando `FinalRoom` emite `player_entered` (el espectador cruza el plano de la puerta),
llama a `Hud.play_crossing()`, `DoorController.extinguish()` y
`AudioController.fade_to_silence()`. Las tres acciones son irreversibles.

## Audio

Todo el audio es original y se genera con `python3 tools/generate_audio.py`, que solo
usa la biblioteca estándar:

- `ambient_drone.wav`: bucle de 32 s, zumbido grave en 55 Hz con quinta, octava y aire filtrado.
- `anticipation_layer.wav`: bucle de 32 s, acorde suspendido La–Mi–Si que nunca resuelve.

Los bucles no tienen costuras: frecuencias con un número entero de ciclos y un bloque
`smpl` con los puntos de bucle, que Godot detecta al importar. Según la anticipación,
el zumbido va de −20 a −9 dB, la capa armónica aparece a partir del 12 % del recorrido
(hasta −11 dB) y el filtro paso bajo del bus se abre de 650 Hz a 7 kHz.

## Parámetros para ajustar el ritmo

Todos se editan en el inspector:

- **Player**: `walk_speed` (1,6 m/s; el recorrido dura unos 35 s).
- **Main**:
  - `glare_distance` (3,5 m): distancia a la que empieza el resplandor;
  - `glare_max_before_crossing` (0,85): intensidad máxima del resplandor antes de cruzar;
  - `anticipation_response`: lo rápido que luz y sonido siguen a la posición.
- **Hud**:
  - `glare_hold` (1,2 s): tiempo en blanco total tras cruzar;
  - `glare_to_dark_duration` (3 s): paso del blanco al negro.
- **Door**: rangos de energía del haz y del halo.
- **AudioController**: volúmenes y `silence_fade_duration` (2,5 s).
- La distancia de la puerta (z = −55) está fijada en las escenas: posición de `Door` y
  `FinalRoom` en `main.tscn` y longitud de `corridor.tscn`.

## Pruebas realizadas

```sh
godot --path . --script res://tests/autotest.gd -- --shots=/ruta/capturas   # con ventana
godot --headless --path . --script res://tests/autotest.gd                  # sin ventana
```

Durante la prueba se desvinculan las teclas físicas de las acciones, para que el
teclado del escritorio no interfiera con el recorrido simulado.

Resultado (Godot 4.7.2, Linux, NVIDIA RTX 3050, Vulkan): **todas las comprobaciones
superadas, con ventana y en headless.**

- Forward+ activo. Los bucles de audio están configurados como bucle. La única fuente
  de luz es la puerta.
- Posición inicial correcta, sobre el suelo, a 55,8 m de la puerta.
- Colisiones: el muro del inicio y las paredes laterales detienen al jugador. El giro
  del pasillo está limitado a 35°.
- El sonido crece de forma monótona (zumbido de −19,9 a −10,1 dB; capa armónica de
  inaudible a −11,4 dB), con un cambio máximo de 0,36 dB/s. Al retroceder, disminuye.
- La luz del haz se intensifica (energía de 11 a 15,5). No hay resplandor a 6 m; a
  1,2 m el resplandor está en 0,53.
- La puerta se atraviesa sin abrirse. Al cruzar: blanco total, la puerta se apaga y
  después llega el negro total. Se midió el brillo de la captura: máximo 0,000.
- El sonido se desvanece en 2,50 s hasta el silencio absoluto (bus silenciado y capas
  detenidas).
- La oscuridad y el silencio persisten al moverse y al volver al pasillo.

**Revisión visual.** Se compararon capturas reales con la imagen de referencia. Sirvió
para corregir:
- un *glow* excesivo que difuminaba la puerta;
- el haz, que iluminaba el techo y las paredes;
- unas "alas" de luz en las paredes laterales.

**No verificado:**
- la escucha real del audio por altavoces;
- el manejo con teclado y ratón físicos por una persona;
- la respuesta emocional, que requiere pruebas con público.

## Limitaciones conocidas

- Al cerrar, Godot 4.7.2 escribe en consola avisos ("ObjectDB instances were leaked",
  "resources still in use") sobre los `AudioStreamWAV` que estaban sonando. Es un
  comportamiento del motor: se reproduce con un proyecto vacío que solo contiene un
  `AudioStreamPlayer` reproduciendo, y no afecta a la obra.
- `assets/sugerencias/` contiene un MP3 comercial que la obra no usa. Si se exporta o
  distribuye el proyecto, conviene excluir esa carpeta, además de `tests/`.
- No hay preset de exportación ni menú para salir (de forma deliberada).
