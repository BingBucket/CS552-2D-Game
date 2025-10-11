extends Area2D
#tile size that the player can move in; change this to be something that is instantiated immediately upon playing the game instead of being local.
var tile_size = 64
var movement = {"right": Vector2.RIGHT,
			  "left": Vector2.LEFT,
			  "up": Vector2.UP,
			  "down": Vector2.DOWN}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2
	print("ready!")

func _unhandled_input(input: InputEvent):
	for direction in movement.keys():
		if input.is_action_pressed(direction):
			move(direction)
			print(direction)
func move(direction):
	position += movement[direction] * tile_size
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
