# EXPECTADOOR

Experiencia interactiva en primera persona, desarrollada en Godot.

## Concepto

*EXPECTADOOR* trata sobre la **expectativa incumplida**: la distancia entre el futuro
que se imagina durante la espera y lo que finalmente se encuentra.

El espectador recorre un pasillo oscuro hacia una única puerta iluminada. Mientras
avanza, la luz cálida de la puerta y una atmósfera sonora cada vez más presente
construyen la impresión de que algo aguarda al otro lado. Al abrirla y entrar,
encuentra una habitación vacía, iluminada con una luz neutra y corriente. El sonido
se desvanece hasta el silencio y no ocurre nada más.

La obra no explica su significado. No hay meta, recompensa, puntuación, texto final
ni pantalla de victoria. La aplicación sigue en marcha y el espectador puede
permanecer en la habitación todo el tiempo que quiera.

La experiencia se articula en cuatro fases, implementadas como estados en
`ExperienceController`:

| Fase | Qué ocurre |
|---|---|
| **PROMISE** (la promesa) | Fundido desde negro. La puerta cálida se ve al fondo de un pasillo frío y oscuro; el sonido es tenue. |
| **APPROACH** (la aproximación) | Luz de la puerta y sonido crecen con la cercanía real del espectador; responden también si se detiene o retrocede. |
| **THRESHOLD** (el umbral) | Con `E`, el picaporte suena, la luz que se filtraba por las rendijas se apaga y la hoja gira despacio hacia dentro. |
| **ABSENCE** (la ausencia) | Al entrar, todo el sonido se desvanece en 2,5 s hasta el silencio absoluto, que ya no se interrumpe. |

### Decisiones de dirección artística

- **Contraste de temperatura.** El pasillo es azul, oscuro y con niebla volumétrica
  muy ligera. La puerta es el único foco cálido. La habitación tiene una luz blanca
  neutra, plana, sin misterio, y una `FogVolume` de densidad negativa le quita la
  bruma: el aire es nítido.
- **La luz que prometía algo desaparece.** El resplandor cálido de las rendijas sale
  de un plano emisivo situado detrás de la hoja, que se apaga al abrir la puerta.
  Detrás solo está la luz corriente de la habitación.
- **Vacío intencionado, no inacabado.** La habitación tiene acabados reales: zócalos,
  marco de puerta por ambos lados, una luminaria empotrada y paredes de pintura lisa.
  Se percibe como un lugar construido y terminado en el que no hay nada.
- **Sonido sin promesa concreta.** Un zumbido grave y un acorde suspendido (La–Mi–Si)
  que nunca resuelve. Un filtro paso bajo se abre al acercarse, de modo que el sonido
  se vuelve más nítido además de más intenso.
- Sin sobresaltos, sin parpadeos, sin elementos de terror.

## Requisitos técnicos

- **Godot 4.7.2** (probado con `4.7.2.stable.nixpkgs`). Debería funcionar en cualquier
  Godot 4.4 o posterior; solo se ha probado en 4.7.2.
- **Renderizador: Forward+.** Está configurado explícitamente en `project.godot`:
  ```ini
  config/features=PackedStringArray("4.7", "Forward Plus")
  [rendering]
  renderer/rendering_method="forward_plus"
  ```
  La prueba automatizada verifica que el método activo en ejecución es `forward_plus`
  (Vulkan, NVIDIA RTX 3050).
- Física: Jolt Physics (integrada en Godot 4.4 y posteriores).
- Sin dependencias externas. Toda la geometría y los materiales están creados en Godot,
  y el audio se genera localmente.
- Resolución inicial: 1280 × 720, con `stretch_mode = canvas_items` y aspecto `expand`,
  por lo que se adapta a otras resoluciones.

## Abrir y ejecutar

1. Abrir Godot 4.x y elegir **Importar**. Seleccionar `project.godot` de esta carpeta.
2. Pulsar **Ejecutar proyecto** (F5). La escena principal es `res://scenes/main.tscn`.

Desde la terminal:

```sh
godot --path .            # ejecuta la obra
godot -e --path .         # abre el editor
```

## Controles

| Tecla | Acción |
|---|---|
| `W` / `↑` | Avanzar |
| `S` / `↓` | Retroceder |
| Ratón | Mirar (giro limitado) |
| `E` | Abrir la puerta, solo desde el umbral |
| `Esc` | Liberar o volver a capturar el cursor (no cierra la aplicación) |
| Clic | Volver a capturar el cursor si estaba liberado |

En el pasillo, el desplazamiento sigue el eje del recorrido y la mirada está limitada
a ±35° en horizontal y ±20° en vertical. Dentro de la habitación se camina hacia donde
se mira, con ±140° y ±40°, suficiente para recorrer el espacio con la vista. No hay
salto, carrera, inventario ni avance automático. Para salir de la aplicación se cierra
la ventana (o `Alt+F4`).

## Estructura

```
project.godot
icon.svg
scenes/
  main.tscn            Escena principal: entorno, pasillo, puerta, habitación, jugador, audio, HUD
  corridor.tscn        Pasillo (32 m): muros, zócalos, luminarias frías
  door.tscn            Marco, hoja con bisagra, luz cálida, zona de interacción, sonido
  final_room.tscn      Habitación vacía de 8 × 8 × 3,8 m, luz neutra, volumen de detección
  player.tscn          CharacterBody3D + cabeza + cámara
  hud.tscn             Fundido de entrada e indicaciones discretas
scripts/
  experience_controller.gd   Fases de la obra y cálculo de la anticipación (0 → 1)
  player_controller.gd       Movimiento guiado y mirada limitada
  door_controller.gd         Apertura, luz de la puerta y zona de interacción
  audio_controller.gd        Mezcla según la cercanía y desvanecimiento definitivo
  final_room.gd              Señales de entrada y salida de la habitación
  hud.gd                     Indicaciones y fundido
assets/
  audio/               WAV generados y bus "Ambience" (default_bus_layout.tres)
  materials/           Materiales StandardMaterial3D y texturas de ruido procedurales
tests/
  autotest.gd          Recorrido automatizado con comprobaciones (no forma parte de la obra)
tools/
  generate_audio.py    Generador del audio (herramienta de desarrollo; Godot la ignora)
```

### Componentes y comunicación

- **ExperienceController** (raíz de `main.tscn`) calcula la distancia del espectador a
  la puerta sobre el eje del recorrido, la suaviza y la transmite como *anticipación*
  (0 → 1) a la puerta y al audio. Escucha las señales `DoorController.opening_started`,
  `DoorController.interaction_available_changed` y
  `FinalRoom.player_entered` / `player_exited`.
- **DoorController** detecta al espectador con un `Area3D` situado ante la puerta y
  atiende la acción `interact` solo desde ahí y una única vez. La hoja es un
  `AnimatableBody3D` cuyo origen coincide con las bisagras. Al animarse su propia
  rotación en el paso de física, la colisión acompaña al giro (96°, 4,5 s,
  aceleración sinusoidal).
- **AudioController** envía todo el sonido de la obra, incluido el de la puerta, al bus
  `Ambience`. `fade_to_silence()` baja el bus de 0 a −60 dB en 2,5 s, lo silencia,
  detiene las capas y no puede revertirse.
- Capas físicas: 1 `world`, 2 `player`. Las áreas no tienen capa propia y solo
  detectan la capa 2.

## Audio

Todo el audio es original y se genera con `tools/generate_audio.py`, que solo usa la
biblioteca estándar de Python:

```sh
python3 tools/generate_audio.py
```

| Archivo | Contenido |
|---|---|
| `ambient_drone.wav` | Bucle de 32 s: fundamental en 55 Hz con quinta, octava y batidos lentos, más aire filtrado. |
| `anticipation_layer.wav` | Bucle de 32 s: acorde suspendido La–Mi–Si con voces ligeramente desafinadas y un brillo muy tenue. |
| `door_open.wav` | 3,5 s: chasquido de picaporte y pestillo, y un desplazamiento de aire suave. |

Todas las frecuencias de los bucles completan un número entero de ciclos en 32 s, y el
ruido se funde consigo mismo, así que los bucles no tienen costuras. Los puntos de
bucle van en un bloque `smpl` del WAV, que Godot detecta al importar (modo *Detect From
WAV*). La generación es determinista (semilla fija).

Mezcla según la anticipación `a`:
- Zumbido: de −20 dB a −9 dB.
- Capa armónica: inaudible hasta `a ≈ 0,12`; después sube con una curva suave hasta −11 dB.
- Filtro paso bajo del bus: de 650 Hz a 7 kHz (interpolación exponencial).

## Ajustar el ritmo para pruebas con público

Los parámetros que más influyen en la vivencia están exportados y se pueden editar en el
inspector:

- `Player`: `walk_speed` (1,6 m/s), aceleración, límites de giro.
- `Main` (ExperienceController): `anticipation_response` (lo rápido que luz y sonido
  siguen a la posición), `arrival_distance`.
- `Door`: `open_duration`, `open_angle_degrees`, `latch_delay` y los rangos de energía
  de las luces.
- `AudioController`: rangos de volumen, `anticipation_onset`, `silence_fade_duration`.
- `Hud`: duración del fundido inicial y de las indicaciones.

## Pruebas realizadas

`tests/autotest.gd` simula un recorrido completo mediante acciones de entrada (las
mismas que generan el teclado) y comprueba cada fase:

```sh
# Con ventana (Forward+ real) y capturas de pantalla:
godot --path . --script res://tests/autotest.gd -- --shots=/ruta/a/capturas
# Sin interfaz gráfica:
godot --headless --path . --script res://tests/autotest.gd
```

Durante la prueba se desvinculan las teclas físicas de las acciones, para que el
teclado del escritorio no interfiera con el recorrido simulado.

Resultados (Godot 4.7.2, Linux, NVIDIA RTX 3050, Vulkan 1.4): **todas las
comprobaciones superadas, tanto con ventana como en headless.**

| # | Prueba | Resultado |
|---|---|---|
| 1 | El proyecto se importa (`--headless --import`) sin errores | ✔ |
| 2 | Forward+ configurado y activo en ejecución | ✔ |
| 3 | La escena principal se ejecuta sin errores ni advertencias (salvo el aviso del motor al cerrar, ver *Limitaciones*) | ✔ |
| 4 | Posición inicial correcta (0; 0; 0,8) y sobre el suelo | ✔ |
| 5 | Movimiento hacia delante y atrás; giro limitado a 35° en el pasillo | ✔ |
| 6 | Colisiones: el muro del inicio, las paredes laterales y las de la habitación detienen al jugador | ✔ |
| 7 | La puerta no se abre desde lejos; desde el umbral sí, y solo una vez aunque se pulse `E` de nuevo | ✔ |
| 8 | Indicación "E" visible en el umbral y retirada al abrir | ✔ |
| 9 | La hoja termina de abrirse y el jugador atraviesa la puerta | ✔ |
| 10 | La habitación solo contiene arquitectura y su luz | ✔ |
| 11 | El sonido crece de forma monótona al acercarse (zumbido de −19,8 a −9,2 dB, capa armónica de inaudible a −11 dB) sin saltos (máx. 0,6 dB/s) | ✔ |
| 12 | Al retroceder, el sonido disminuye | ✔ |
| 13 | La luz de la puerta se intensifica (energía de 1,6 a 4,1) | ✔ |
| 14 | Al entrar, desvanecimiento gradual de 2,5 s hasta el silencio absoluto (bus silenciado, capas detenidas) | ✔ |
| 15 | El silencio persiste al recorrer la habitación y al volver al pasillo | ✔ |
| 16 | Al volver al pasillo se restablece el movimiento guiado | ✔ |

**Revisión visual.** Se ejecutó con ventana sobre Forward+ y se revisaron capturas del
inicio, la mitad del pasillo, la llegada, la apertura, la puerta abierta y el interior
de la habitación desde varios ángulos. Esa revisión permitió corregir lo siguiente:

- z-fighting entre los muros del pasillo y la cara interior de la habitación;
- grano producido por las sombras suaves (PCSS) de las luces;
- un ruido de textura que hacía que la habitación pareciera sucia;
- un reflejo especular duro bajo la puerta;
- la legibilidad de la indicación "E" sobre la puerta clara.

**Lo que no se ha podido verificar:**

- La escucha real del audio. Los niveles se midieron en el motor, pero la mezcla no se
  ha escuchado por altavoces.
- La sensación con el ratón y el teclado físicos. El recorrido se simuló con acciones
  de entrada, no con una persona jugando.
- La respuesta emocional, que solo puede valorarse probándolo con otras personas.

## Limitaciones conocidas

- Al cerrar la aplicación, Godot 4.7.2 escribe en la consola dos avisos ("ObjectDB
  instances were leaked", "resources still in use") sobre los `AudioStreamWAV` que
  estaban sonando. Es un comportamiento del motor: se reproduce con un proyecto vacío
  que solo contiene un `AudioStreamPlayer` reproduciendo, con o sin ventana, y no
  desaparece aunque se llame a `stop()` o se suelte el stream en `_exit_tree`. Solo
  ocurre en el cierre y no afecta a la obra.
- No hay menú ni opción para salir dentro de la obra, de forma deliberada. Se sale
  cerrando la ventana.
- No hay preset de exportación. Si se exporta, conviene excluir `tests/` (y `tools/`,
  que ya lleva `.gdignore`).
- La niebla volumétrica y el SSR requieren una GPU compatible con Forward+ (Vulkan,
  D3D12 o Metal).
