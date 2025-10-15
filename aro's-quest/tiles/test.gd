extends Node2D
@onready var tile_layer = $layer1
@onready var player = $player
func _ready() -> void:
	var connected = 0
	await get_tree().process_frame
	print("connected: " + str(connected))
	if tile_layer.get_children():
		print(tile_layer.get_children())
	else:
		return
	for tile in tile_layer.get_children():
		print("tile" + str(tile))
		if tile.has_signal("pushed"):
			tile.connect("pushed", Callable(player, "on_pushed"))
			connected +=1
			print(connected)
		if tile.has_signal("collected"):
			print("bug found!")
