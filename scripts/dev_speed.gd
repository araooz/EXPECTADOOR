class_name DevSpeed
extends Node
## SOLO PARA DESARROLLO: acelera toda la experiencia para revisarla más rápido.
##   1  x2      2  x4      3  x8      4  x16   (la misma tecla otra vez vuelve a x1)
##
## Acelera la canción (y con ella el recorrido, que la usa como reloj) y el
## reloj del motor (tweens y temporizadores: aparición de la luz, huella, eco).
## La música sube de tono al acelerarse. En una exportación release este nodo
## se elimina solo, y para quitarlo del todo basta con borrarlo de main.tscn.

const SPEEDS := {
	&"dev_speed_x2": 2.0,
	&"dev_speed_x4": 4.0,
	&"dev_speed_x8": 8.0,
	&"dev_speed_x16": 16.0,
}

var speed: float = 1.0

@onready var _audio: AudioController = $"../AudioController"


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()


func _unhandled_input(event: InputEvent) -> void:
	for action: StringName in SPEEDS:
		if event.is_action_pressed(action):
			set_speed(1.0 if is_equal_approx(speed, SPEEDS[action]) else SPEEDS[action])
			get_viewport().set_input_as_handled()
			return


func set_speed(value: float) -> void:
	speed = value
	Engine.time_scale = value
	_audio.set_playback_speed(value)
	print("EXPECTADOOR [desarrollo]: velocidad x%d" % int(value))


func _exit_tree() -> void:
	Engine.time_scale = 1.0
