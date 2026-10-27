class_name FinalRoom
extends Node3D
## La habitación final. Solo informa de cuándo el espectador entra o sale.

signal player_entered(player: Node3D)
signal player_exited(player: Node3D)

@onready var _room_volume: Area3D = $RoomVolume


func _ready() -> void:
	_room_volume.body_entered.connect(_on_body_entered)
	_room_volume.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(body)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_exited.emit(body)
