extends Node

var bugs_collected = 0
var tile_size = 64
var movement = {"right": Vector2.RIGHT,
			  "left": Vector2.LEFT,
			  "up": Vector2.UP,
			  "down": Vector2.DOWN}
var player_next_position = Vector2(0,0)
