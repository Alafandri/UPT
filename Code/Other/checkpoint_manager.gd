extends Node

var last_location: Vector2 = Vector2.ZERO

func _ready() -> void:
	var player = get_parent().get_node("player")
	if player:
		last_location = player.global_position
