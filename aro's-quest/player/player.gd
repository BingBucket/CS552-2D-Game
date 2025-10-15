extends CharacterBody2D

var grappling: bool = false
@onready var ray = $RayCast2D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("player")
	print("ready!")

func _unhandled_input(input: InputEvent):
	for direction in Global.movement.keys():
		if input.is_action_pressed(direction):
			move(direction)
			print(direction)
func move(direction):
	if grappling:
		position += Global.movement[direction] * Global.tile_size
	else:
		ray.target_position = Global.movement[direction] * Global.tile_size
		ray.force_raycast_update()
		if ray.is_colliding():
			print("crash!")
		else:
			position += Global.movement[direction] * Global.tile_size
		
	
	

func on_pushed():
	print("hi")
	position = Global.player_next_position

func update_position():
	position = Global.player_next_position
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
