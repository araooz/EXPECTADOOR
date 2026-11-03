extends SceneTree
## Recorrido automatizado de EXPECTADOOR: simula al espectador, comprueba cada
## fase y, si hay una sesión gráfica, guarda capturas de los momentos clave.
##
## Uso (desde la carpeta del proyecto):
##   godot --path . --script res://tests/autotest.gd -- --shots=/ruta/capturas
##   godot --headless --path . --script res://tests/autotest.gd   (sin capturas)

const MAIN_SCENE := "res://scenes/main.tscn"

var _failures: Array[String] = []
var _shots_dir: String = ""
var _main: ExperienceController
var _player: PlayerController
var _door: DoorController
var _audio: AudioController
var _hud: Hud
var _absence_time: float = -1.0
var _music_finished: bool = false
## Tiempo de juego acumulado (el mismo reloj que usan los tweens).
var _game_time: float = 0.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	_run.call_deferred()


func _process(delta: float) -> bool:
	_game_time += delta
	return false


func _run() -> void:
	# La ventana de prueba puede recibir el teclado real del escritorio; se
	# desvinculan las teclas de las acciones para que no alteren el recorrido.
	# Las acciones simuladas (Input.action_press) siguen funcionando.
	for action in [&"move_forward", &"move_back", &"toggle_mouse_capture"]:
		InputMap.action_erase_events(action)
	var packed: PackedScene = load(MAIN_SCENE)
	_main = packed.instantiate()
	root.add_child(_main)
	current_scene = _main
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # no retener el cursor durante la prueba
	_player = _main.get_node("Player")
	_door = _main.get_node("Door")
	_audio = _main.get_node("AudioController")
	_hud = _main.get_node("Hud")
	_main.phase_changed.connect(func(p: ExperienceController.Phase) -> void:
		if p == ExperienceController.Phase.ABSENCE:
			_absence_time = _game_time)
	_audio.music_finished.connect(func() -> void: _music_finished = true)

	print("== Configuración")
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus",
			"renderer = forward_plus")
	_check(RenderingServer.get_current_rendering_method() == "forward_plus" or DisplayServer.get_name() == "headless",
			"método de renderizado activo: %s" % RenderingServer.get_current_rendering_method())
	var music_stream: AudioStreamMP3 = _main.get_node("AudioController/Music").stream
	_check(music_stream != null, "la canción está cargada")
	_check(is_equal_approx(_audio.get_bar_length(), 2.5), "a 96 BPM un compás dura 2,5 s")
	_check(is_equal_approx(_audio.get_approach_loop_end(), 102.5),
			"el bucle previo al cruce termina en el compás anterior a 1:43 (%.1f s)" % _audio.get_approach_loop_end())
	_check(_only_light_is_door(), "la única fuente de luz es la puerta")

	print("== Estado 0: oscuridad")
	await _wait(2.0)
	_check(_main.phase == ExperienceController.Phase.DARKNESS, "fase DARKNESS")
	_check(not _door.is_revealed, "la luz todavía no aparece")
	_check(not _audio.is_music_playing(), "sin música al comienzo")
	await _shot("00_oscuridad")
	if _can_capture():
		_check(_max_brightness() < 0.01, "la imagen inicial es negro puro (máx %.3f)" % _max_brightness())

	print("== Estado 1: la promesa")
	await _wait(5.0)
	_check(_player.global_position.distance_to(Vector3(0, 0, 0.8)) < 0.05,
			"posición inicial (%s)" % _player.global_position)
	_check(_player.is_on_floor(), "el jugador está sobre el suelo")
	_check(_main.distance_to_door() > 70.0, "la puerta está lejos (%.1f m)" % _main.distance_to_door())
	_check(_main.phase == ExperienceController.Phase.PROMISE, "fase PROMISE")
	_check(_door.is_revealed and _door.get_shape() < 0.01, "aparece un punto de luz (forma %.2f)" % _door.get_shape())
	_check(_audio.is_music_playing(), "la música comienza")
	await _shot("01_punto")

	print("== Colisiones")
	Input.action_press("move_back")
	await _wait(3.0)
	Input.action_release("move_back")
	_check(_player.global_position.z < 1.71, "el muro de inicio detiene el retroceso (z=%.2f)" % _player.global_position.z)
	_player.free_roam = true
	_player.set_look_target(-90, 0)  # mirar hacia +X
	await _wait(0.8)
	Input.action_press("move_forward")
	await _wait(3.5)
	Input.action_release("move_forward")
	_check(_player.global_position.x < 5.71, "la pared lateral (invisible en la oscuridad) detiene al jugador (x=%.2f)" % _player.global_position.x)
	_player.free_roam = false
	_player.global_position = Vector3(0, 0.02, 0.8)
	_player.velocity = Vector3.ZERO
	_player.set_look_target(-180, 0)  # mirar hacia atrás, sin límite de giro
	await _wait(1.0)
	_check(absf(_player.get_look_yaw_degrees() + 180.0) < 5.0,
			"la mirada gira libremente en el pasillo (%.1f°)" % _player.get_look_yaw_degrees())
	_player.set_look_target(0, 0)
	await _wait(1.0)

	print("== Estado 2: la aproximación")
	var music_samples: Array[float] = []
	var shape_samples: Array[float] = []
	var floor_light_far := -1.0
	var beam: SpotLight3D = _door.get_node("Beam")
	var beam_start := beam.light_energy
	Input.action_press("move_forward")
	var shot_taken := false
	while _main.distance_to_door() > 6.0:
		await _wait(1.0)
		music_samples.append(_audio.get_music_volume_db())
		shape_samples.append(_door.get_shape())
		if floor_light_far < 0.0 and _main.distance_to_door() < 45.0:
			floor_light_far = beam.light_energy
		if not shot_taken and _main.distance_to_door() < 35.0:
			shot_taken = true
			await _shot("02_aproximacion")
	Input.action_release("move_forward")
	_check(_main.phase == ExperienceController.Phase.APPROACH, "fase APPROACH")
	_check(_is_non_decreasing(music_samples), "la música crece de forma monótona: %s" % _fmt(music_samples))
	_check(music_samples[-1] - music_samples[0] > 15.0, "el aumento es claramente perceptible")
	_check(_max_step(music_samples) < 4.0, "sin saltos bruscos de volumen (máx %.2f dB/s)" % _max_step(music_samples))
	_check(_is_non_decreasing(shape_samples) and shape_samples[-1] > 0.99,
			"el punto toma forma de puerta: %s" % _fmt(shape_samples))
	_check(floor_light_far == 0.0, "con solo el punto visible, el suelo no recibe luz")
	_check(beam.light_energy > beam_start + 2.0, "la luz de la puerta se intensifica (%.1f → %.1f)" % [beam_start, beam.light_energy])
	_check(_hud.get_veil_color().a < 0.01, "todavía sin resplandor a 6 m")

	print("== Retroceder y detenerse")
	await _wait(2.0)
	var before := _audio.get_music_volume_db()
	Input.action_press("move_back")
	await _wait(3.0)
	Input.action_release("move_back")
	await _wait(1.5)
	_check(_audio.get_music_volume_db() < before, "al retroceder la música disminuye")

	print("== Bucle cuantizado")
	_check(_audio.get_music_position() < _audio.get_approach_loop_end(),
			"antes de cruzar, la canción no llega a 1:43 (%.1f s)" % _audio.get_music_position())
	_audio._music.seek(_audio.get_approach_loop_end() - 0.5)
	await _wait(1.0)
	_check(_audio.is_music_playing() and _audio.get_music_position() < 2.0,
			"al llegar al fin del compás vuelve al inicio (%.1f s)" % _audio.get_music_position())

	print("== Estado 3: el umbral")
	Input.action_press("move_forward")
	while _main.distance_to_door() > 2.2:  # frenar a 3,2 m/s lleva ~1 m
		await _wait(0.1)
	Input.action_release("move_forward")
	await _wait(0.6)
	_check(_main.phase == ExperienceController.Phase.THRESHOLD, "fase THRESHOLD")
	var glare := _hud.get_veil_color().a
	_check(glare > 0.05 and glare < 0.95, "el resplandor crece ante la puerta (%.2f)" % glare)
	await _shot("03_umbral")

	print("== Estado 4: el cruce y la ausencia")
	Input.action_press("move_forward")
	await _wait(1.6)
	_check(_main.phase == ExperienceController.Phase.ABSENCE, "la puerta se atraviesa sin abrirse (z=%.2f)" % _player.global_position.z)
	_check(_door.is_extinguished, "la luz de la puerta se extingue al cruzar")
	var cue_position := _audio.get_music_position()
	var crossing_elapsed := _game_time - _absence_time
	_check(_audio.is_music_playing() and cue_position >= 103.0 and cue_position <= 103.0 + crossing_elapsed + 0.2,
			"al cruzar suena el minuto 1:43 (%.1f s, %.1f s después del cruce)" % [cue_position, crossing_elapsed])
	_check(absf(_audio.get_music_volume_db() - (-2.0)) < 0.1, "el fragmento del cruce suena a plena intensidad (%.1f dB)" % _audio.get_music_volume_db())
	_check(_audio.get_lowpass_cutoff_hz() > 19000.0, "y sin filtro (%.0f Hz)" % _audio.get_lowpass_cutoff_hz())
	var veil := _hud.get_veil_color()
	_check(veil.a > 0.99 and veil.v > 0.99, "todo queda blanco al cruzar")
	await _wait(1.0)
	Input.action_release("move_forward")
	await _wait(3.0)
	await _shot("04_blanco")
	if _can_capture():
		_check(_min_brightness() > 0.99, "la imagen es blanco puro (mín %.3f)" % _min_brightness())

	_check(_audio.is_music_playing() and not _music_finished, "la música sigue sonando en el blanco")

	print("== Fin de la música: 2:15")
	_audio._music.seek(133.0)
	await _wait(1.5)
	_check(_audio.is_music_playing() and _audio.get_music_volume_db() < -2.5,
			"la música se desvanece antes de 2:15 (%.1f dB)" % _audio.get_music_volume_db())
	await _wait(1.5)
	_check(_music_finished and not _audio.is_music_playing(), "a las 2:15 queda el silencio")

	print("== El blanco y el silencio persisten")
	_player.set_look_target(120, 0)
	Input.action_press("move_forward")
	await _wait(3.0)
	Input.action_release("move_forward")
	_check(_player.free_roam, "más allá de la puerta se puede caminar libremente")
	_player.set_look_target(0, 0)
	_player.global_position = Vector3(0, 0.02, -75.8)
	await _wait(1.0)
	Input.action_press("move_back")
	await _wait(3.0)
	Input.action_release("move_back")
	_check(_player.global_position.z > -75.0, "se puede volver al pasillo (z=%.2f)" % _player.global_position.z)
	await _wait(2.0)
	veil = _hud.get_veil_color()
	_check(veil.a > 0.99 and veil.v > 0.99, "el blanco no se retira")
	_check(not _audio.is_music_playing(), "el sonido no se reanuda")

	print("")
	if _failures.is_empty():
		print("RESULTADO: todas las comprobaciones superadas")
	else:
		print("RESULTADO: %d fallos" % _failures.size())
		for f in _failures:
			print("  - ", f)
	quit(0 if _failures.is_empty() else 1)


func _check(ok: bool, label: String) -> void:
	print(("  [OK] " if ok else "  [FALLO] ") + label)
	if not ok:
		_failures.append(label)


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _only_light_is_door() -> bool:
	var env: Environment = _main.get_node("WorldEnvironment").environment
	if env.ambient_light_energy > 0.0 or env.background_color.v > 0.0:
		return false
	for light in _main.find_children("*", "Light3D", true, false):
		if not _door.is_ancestor_of(light):
			return false
	return true


func _can_capture() -> bool:
	return not _shots_dir.is_empty() and DisplayServer.get_name() != "headless"


func _shot(shot_name: String) -> void:
	if not _can_capture():
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := _shots_dir.path_join(shot_name + ".png")
	img.save_png(path)
	print("  captura: ", path)


func _max_brightness() -> float:
	var img := root.get_texture().get_image()
	var m := 0.0
	for y in range(0, img.get_height(), 8):
		for x in range(0, img.get_width(), 8):
			m = maxf(m, img.get_pixel(x, y).v)
	return m


func _min_brightness() -> float:
	var img := root.get_texture().get_image()
	var m := 1.0
	for y in range(0, img.get_height(), 8):
		for x in range(0, img.get_width(), 8):
			m = minf(m, img.get_pixel(x, y).v)
	return m


func _is_non_decreasing(values: Array[float]) -> bool:
	for i in range(1, values.size()):
		if values[i] < values[i - 1] - 0.01:
			return false
	return values.size() > 1


func _max_step(values: Array[float]) -> float:
	var m := 0.0
	for i in range(1, values.size()):
		m = maxf(m, absf(values[i] - values[i - 1]))
	return m


func _fmt(values: Array[float]) -> String:
	return ", ".join(values.map(func(v: float) -> String: return "%.1f" % v))
