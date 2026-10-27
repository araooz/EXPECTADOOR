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
var _silence_time: float = -1.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.trim_prefix("--shots=")
	_run.call_deferred()


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
			_absence_time = Time.get_ticks_msec() / 1000.0)
	_audio.silence_reached.connect(func() -> void: _silence_time = Time.get_ticks_msec() / 1000.0)

	print("== Configuración")
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "forward_plus",
			"renderer = forward_plus")
	_check(RenderingServer.get_current_rendering_method() == "forward_plus" or DisplayServer.get_name() == "headless",
			"método de renderizado activo: %s" % RenderingServer.get_current_rendering_method())
	var drone_stream: AudioStreamWAV = _main.get_node("AudioController/DroneLayer").stream
	var layer_stream: AudioStreamWAV = _main.get_node("AudioController/AnticipationLayer").stream
	_check(drone_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "el zumbido está en bucle")
	_check(layer_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "la capa de anticipación está en bucle")
	_check(_only_light_is_door(), "la única fuente de luz es la puerta")

	print("== Estado 1: la promesa")
	await _wait(4.5)
	_check(_player.global_position.distance_to(Vector3(0, 0, 0.8)) < 0.05,
			"posición inicial (%s)" % _player.global_position)
	_check(_player.is_on_floor(), "el jugador está sobre el suelo")
	_check(_main.distance_to_door() > 50.0, "la puerta está lejos (%.1f m)" % _main.distance_to_door())
	_check(_main.phase == ExperienceController.Phase.PROMISE, "fase PROMISE")
	_check(_audio.is_any_layer_playing(), "el ambiente sonoro suena")
	await _shot("01_promesa")

	print("== Colisiones")
	Input.action_press("move_back")
	await _wait(3.0)
	Input.action_release("move_back")
	_check(_player.global_position.z < 1.71, "el muro de inicio detiene el retroceso (z=%.2f)" % _player.global_position.z)
	_player.free_roam = true
	_player.set_look_target(-90, 0)  # mirar hacia +X
	await _wait(0.8)
	Input.action_press("move_forward")
	await _wait(2.5)
	Input.action_release("move_forward")
	_check(_player.global_position.x < 1.11, "la pared lateral (invisible en la oscuridad) detiene al jugador (x=%.2f)" % _player.global_position.x)
	_player.free_roam = false
	_player.global_position = Vector3(0, 0.02, 0.8)
	_player.velocity = Vector3.ZERO
	_player.set_look_target(-90, 0)  # se pide más giro del permitido
	await _wait(1.0)
	_check(absf(_player.get_look_yaw_degrees() + 35.0) < 2.0,
			"límite de giro del pasillo (%.1f°)" % _player.get_look_yaw_degrees())
	_player.set_look_target(0, 0)
	await _wait(1.0)

	print("== Estado 2: la aproximación")
	var drone_samples: Array[float] = []
	var layer_samples: Array[float] = []
	var beam: SpotLight3D = _door.get_node("Beam")
	var beam_start := beam.light_energy
	Input.action_press("move_forward")
	var shot_taken := false
	while _main.distance_to_door() > 6.0:
		await _wait(1.0)
		drone_samples.append(_audio.get_drone_volume_db())
		layer_samples.append(_audio.get_anticipation_volume_db())
		if not shot_taken and _main.distance_to_door() < 30.0:
			shot_taken = true
			await _shot("02_aproximacion")
	Input.action_release("move_forward")
	_check(_main.phase == ExperienceController.Phase.APPROACH, "fase APPROACH")
	_check(_is_non_decreasing(drone_samples), "el zumbido crece de forma monótona: %s" % _fmt(drone_samples))
	_check(_is_non_decreasing(layer_samples), "la capa armónica crece de forma monótona: %s" % _fmt(layer_samples))
	_check(drone_samples[-1] - drone_samples[0] > 6.0, "el aumento es perceptible")
	_check(_max_step(drone_samples) < 3.0, "sin saltos bruscos de volumen (máx %.2f dB/s)" % _max_step(drone_samples))
	_check(beam.light_energy > beam_start + 2.0, "la luz de la puerta se intensifica (%.1f → %.1f)" % [beam_start, beam.light_energy])
	_check(_hud.get_veil_color().a < 0.01, "todavía sin resplandor a 6 m")

	print("== Retroceder y detenerse")
	await _wait(2.0)
	var before := _audio.get_drone_volume_db()
	Input.action_press("move_back")
	await _wait(3.0)
	Input.action_release("move_back")
	await _wait(1.5)
	_check(_audio.get_drone_volume_db() < before, "al retroceder el sonido disminuye")

	print("== Estado 3: el umbral")
	Input.action_press("move_forward")
	while _main.distance_to_door() > 1.2:
		await _wait(0.1)
	Input.action_release("move_forward")
	await _wait(0.6)
	_check(_main.phase == ExperienceController.Phase.THRESHOLD, "fase THRESHOLD")
	var glare := _hud.get_veil_color().a
	_check(glare > 0.3 and glare < 0.95, "el resplandor crece ante la puerta (%.2f)" % glare)
	await _shot("03_umbral")

	print("== Estado 4: el cruce y la ausencia")
	Input.action_press("move_forward")
	await _wait(1.5)
	_check(_main.phase == ExperienceController.Phase.ABSENCE, "la puerta se atraviesa sin abrirse (z=%.2f)" % _player.global_position.z)
	_check(_door.is_extinguished, "la luz de la puerta se extingue al cruzar")
	var veil := _hud.get_veil_color()
	_check(veil.a > 0.99 and veil.v > 0.9, "resplandor blanco total al cruzar")
	await _shot("04_resplandor")
	await _wait(1.5)
	Input.action_release("move_forward")
	await _wait(3.0)
	veil = _hud.get_veil_color()
	_check(veil.a > 0.99 and veil.v < 0.01, "después, oscuridad pura (velo %s)" % veil)
	var fade_duration := _silence_time - _absence_time
	_check(_silence_time > 0.0 and fade_duration >= 1.0 and fade_duration <= 3.2,
			"desvanecimiento sonoro de %.2f s (entre 1 y 3 s)" % fade_duration)
	_check(_audio.is_bus_muted() and not _audio.is_any_layer_playing(), "silencio absoluto")
	await _shot("05_oscuridad")
	if not _shots_dir.is_empty() and DisplayServer.get_name() != "headless":
		_check(_max_brightness() < 0.01, "la imagen es negro puro (máx %.3f)" % _max_brightness())

	print("== La oscuridad y el silencio persisten")
	_player.set_look_target(120, 0)
	Input.action_press("move_forward")
	await _wait(3.0)
	Input.action_release("move_forward")
	_check(_player.free_roam, "más allá de la puerta se puede caminar libremente")
	_player.set_look_target(0, 0)
	_player.global_position = Vector3(0, 0.02, -55.8)
	await _wait(1.0)
	Input.action_press("move_back")
	await _wait(3.0)
	Input.action_release("move_back")
	_check(_player.global_position.z > -55.0, "se puede volver al pasillo (z=%.2f)" % _player.global_position.z)
	await _wait(2.0)
	veil = _hud.get_veil_color()
	_check(veil.a > 0.99 and veil.v < 0.01, "la oscuridad no se retira")
	_check(_audio.is_bus_muted() and not _audio.is_any_layer_playing(), "el sonido no se reanuda")

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


func _shot(shot_name: String) -> void:
	if _shots_dir.is_empty() or DisplayServer.get_name() == "headless":
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
