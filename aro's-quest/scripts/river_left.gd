extends Node2D
@onready var river_sprite = $Area2D/river_sprite
signal pushed
func _ready() -> void:
	print(position)
	river_sprite.play()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_push_player(body)

func _push_player(player: CharacterBody2D):
	Global.player_next_position = position + Global.movement["left"] * Global.tile_size
	emit_signal("pushed")
	
