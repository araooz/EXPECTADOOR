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
var _song_time_at_cut: float = -1.0
var _music_finished: bool = false
## Tiempo de juego acumulado (el mismo reloj que usan los tweens).
var _game_time: float = 0.0
var _start_time: float = 0.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	_run.call_deferred()


func _process(delta: float) -> bool:
	_game_time += delta
	return false


func _run() -> void:
	# La ventana de prueba puede recibir el teclado real del escritorio.
	InputMap.action_erase_events(&"toggle_mouse_capture")
	var packed: PackedScene = load(MAIN_SCENE)
	_main = packed.instantiate()
	_start_time = _game_time
	root.add_child(_main)
	current_scene = _main
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE  # no retener el cursor durante la prueba
	_player = _main.get_node("Player")
	_door = _main.get_node("Door")
	_audio = _main.get_node("AudioController")
	_hud = _main.get_node("Hud")
	_main.phase_changed.connect(func(p: ExperienceController.Phase) -> void:
		if p == ExperienceController.Phase.ABSENCE:
			_absence_time = _game_time - _start_time
			_song_time_at_cut = _audio.get_song_time())
	_audio.music_finished.connect(func() -> void: _music_finished = true)

	print("== Configuración")
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus",
			"renderer = forward_plus")
	_check(RenderingServer.get_current_rendering_method() == "forward_plus" or DisplayServer.get_name() == "headless",
			"método de renderizado activo: %s" % RenderingServer.get_current_rendering_method())
	var music_stream: AudioStreamMP3 = _main.get_node("AudioController/Music").stream
	_check(music_stream != null, "la canción está cargada")
	_check(is_equal_approx(_main.silence_duration, 2.5), "silencio inicial de 2,5 s")
	_check(is_equal_approx(_main.get_total_duration(), 106.0),
			"duración total hasta el cruce: %.2f s (1:46)" % _main.get_total_duration())
	_check(not InputMap.has_action(&"move_forward") and not InputMap.has_action(&"move_back"),
			"no existen acciones de desplazamiento")
	_check(_player.find_children("*", "CollisionObject3D", true, false).is_empty() and not _player.is_class("PhysicsBody3D"),
			"el espectador no es un cuerpo físico")
	_check(_only_light_is_door(), "la única fuente de luz es la puerta")

	print("== Estado 0: oscuridad y silencio")
	await _wait(2.0)
	_check(_main.phase == ExperienceController.Phase.DARKNESS, "fase DARKNESS")
	_check(not _door.is_revealed, "la luz todavía no aparece")
	_check(not _audio.is_music_playing(), "sin música")
	_check(_player.global_position.distance_to(Vector3(0, 0.02, 0.8)) < 0.01,
			"el espectador sigue en la posición inicial (%s)" % _player.global_position)
	await _shot("00_oscuridad")
	if _can_capture():
		_check(_max_brightness() < 0.01, "la imagen inicial es negro puro (máx %.3f)" % _max_brightness())

	print("== Estado 1: la promesa (2,5 s)")
	await _wait(1.0)
	_check(_main.phase >= ExperienceController.Phase.PROMISE, "fase PROMISE")
	_check(_door.is_revealed and _door.get_shape() < 0.01, "aparece un punto de luz (forma %.2f)" % _door.get_shape())
	_check(_audio.is_music_playing(), "la música comienza")
	var sync_error := absf((_main.elapsed - _main.silence_duration) - _audio.get_song_time())
	_check(_audio.get_song_time() < 1.0 and sync_error < 0.05,
			"la canción empieza desde 0:00 al terminar el silencio (%.2f s)" % _audio.get_song_time())
	_check(_main.distance_to_door() > 70.0, "la puerta está lejos (%.1f m)" % _main.distance_to_door())
	await _shot("01_punto")

	print("== La mirada gira, el cuerpo no se desplaza")
	var before_look := _player.global_position
	_player.set_look_target(-180, 0)
	await _wait(1.0)
	_check(absf(_player.get_look_yaw_degrees() + 180.0) < 5.0,
			"la mirada gira libremente (%.1f°)" % _player.get_look_yaw_degrees())
	_check((_player.global_position - before_look).dot(Vector3.FORWARD) >= 0.0 \
			and absf(_player.global_position.x) < 0.001,
			"girar no desvía el recorrido (x=%.3f)" % _player.global_position.x)
	for key in [KEY_W, KEY_UP, KEY_S, KEY_DOWN, KEY_A, KEY_D, KEY_SPACE]:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		ev.pressed = true
		Input.parse_input_event(ev)
	await _wait(0.5)
	var expected := Vector3(0, 0.02, 0.8) + Vector3.FORWARD * _main.get_travelled_distance()
	_check(_player.global_position.distance_to(expected) < 0.01,
			"el teclado no altera la posición (sigue la línea de tiempo)")
	for key in [KEY_W, KEY_UP, KEY_S, KEY_DOWN, KEY_A, KEY_D, KEY_SPACE]:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		ev.pressed = false
		Input.parse_input_event(ev)
	_player.set_look_target(0, 0)

	print("== Estado 2: la aproximación")
	var music_samples: Array[float] = []
	var shape_samples: Array[float] = []
	var distance_samples: Array[float] = []
	var sync_samples: Array[float] = []
	var floor_light_far := -1.0
	var beam: SpotLight3D = _door.get_node("Beam")
	var beam_start := beam.light_energy
	var shot_taken := false
	# En headless el driver de audio simulado avanza ~0,7 % más lento que el reloj real.
	var clock_tolerance := 1.0 if DisplayServer.get_name() == "headless" else 0.3
	while _main.elapsed < 100.0:
		await _wait(2.0)
		music_samples.append(_audio.get_music_volume_db())
		shape_samples.append(_door.get_shape())
		distance_samples.append(_main.distance_to_door())
		sync_samples.append(absf((_game_time - _start_time) - _main.elapsed))
		if floor_light_far < 0.0 and _main.distance_to_door() < 45.0:
			floor_light_far = beam.light_energy
		if not shot_taken and _main.distance_to_door() < 35.0:
			shot_taken = true
			await _shot("02_aproximacion")
	_check(_main.phase == ExperienceController.Phase.APPROACH, "fase APPROACH")
	_check(_is_non_decreasing(music_samples), "la música crece de forma monótona: %s" % _fmt(music_samples))
	_check(music_samples[-1] - music_samples[0] > 15.0, "el aumento es claramente perceptible")
	_check(_max_step(music_samples) < 4.0, "sin saltos bruscos de volumen (máx %.2f dB cada 2 s)" % _max_step(music_samples))
	_check(_is_non_decreasing(shape_samples) and shape_samples[-1] > 0.99,
			"el punto toma forma de puerta: %s" % _fmt(shape_samples))
	var neg: Array[float] = []
	neg.assign(distance_samples.map(func(d: float) -> float: return -d))
	_check(_is_non_decreasing(neg), "el avance es continuo: %s" % _fmt(distance_samples))
	_check(sync_samples.max() < clock_tolerance, "la línea de tiempo (canción) sigue al reloj real (desfase máx %.3f s)" % sync_samples.max())
	_check(floor_light_far == 0.0, "con solo el punto visible, el suelo no recibe luz")
	_check(beam.light_energy > beam_start + 2.0, "la luz de la puerta se intensifica (%.1f → %.1f)" % [beam_start, beam.light_energy])
	_check(_audio.is_music_playing(), "la canción sigue sonando (%.1f s)" % _audio.get_song_time())

	print("== Estado 3: el umbral")
	while _main.elapsed < 104.8:
		await _wait(0.05)
	_check(_main.phase == ExperienceController.Phase.THRESHOLD, "fase THRESHOLD (%.1f m)" % _main.distance_to_door())
	var glare := _hud.get_veil_color().a
	_check(glare > 0.05 and glare < 0.95, "el resplandor crece ante la puerta (%.2f)" % glare)
	await _shot("03_umbral")

	print("== Estado 4: el cruce y el silencio (1:46)")
	while _main.phase != ExperienceController.Phase.ABSENCE and _game_time - _start_time < 115.0:
		await _wait(0.01)
	_check(_main.phase == ExperienceController.Phase.ABSENCE, "la puerta se atraviesa sin abrirse")
	_check(absf(_main.elapsed - 106.0) < 0.05, "el cruce ocurre a 1:46,0 en la línea de tiempo (%.3f s)" % _main.elapsed)
	_check(absf(_absence_time - 106.0) < clock_tolerance,
			"y a %.2f s de reloj real desde el inicio" % _absence_time)
	_check(absf(_song_time_at_cut - _audio.cut_time) < 0.05,
			"la canción se corta en %.2f s (1:43,5)" % _song_time_at_cut)
	_check(_main.distance_to_door() < 0.05, "en el plano de la puerta (%.3f m)" % _main.distance_to_door())
	_check(_door.is_extinguished, "la luz de la puerta se extingue al cruzar")
	await _wait(0.1)
	_check(_music_finished and not _audio.is_music_playing(), "silencio total inmediato")
	await _wait(0.5)
	var veil := _hud.get_veil_color()
	_check(veil.a > 0.99 and veil.v > 0.99, "todo queda blanco al cruzar")

	print("== El blanco y el silencio persisten")
	var final_position := _player.global_position
	_player.set_look_target(120, -30)
	await _wait(3.0)
	await _shot("04_blanco")
	if _can_capture():
		_check(_min_brightness() > 0.99, "la imagen es blanco puro (mín %.3f)" % _min_brightness())
	veil = _hud.get_veil_color()
	_check(veil.a > 0.99 and veil.v > 0.99, "el blanco no se retira")
	_check(not _audio.is_music_playing(), "el sonido no se reanuda")
	_check(_player.global_position.is_equal_approx(final_position), "el espectador queda inmóvil")

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
	return ", ".join(values.map(func(v: float) -> String: return "%.2f" % v))
