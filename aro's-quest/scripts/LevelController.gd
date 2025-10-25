extends Node2D
class_name LevelController

# Level controller script
# Attach to root of each level scene to configure level-specific settings
#
# LEVEL BUILDING GUIDE:
# 1. Enable Grid Snap: Editor → View → Grid Settings → Step: 16x16, Enable Snap
# 2. Use TileMap for VISUAL background only (ground, water texture)
# 3. Instance PREFAB SCENES in Props node for interactive objects:
#    - Right-click Props → "Instantiate Child Scene"
#    - Choose from scenes/prefabs/: Firefly, Cattail, Rock, Water, Whirlpool, Goal
# 4. Position objects will snap to 16x16 grid automatically

@export var level_name: String = "Level 1"
@export var total_fireflies_in_level: int = 0  # Auto-count if 0
@export var time_limit: float = 0.0  # Seconds, 0 = no limit
@export var auto_count_fireflies: bool = true
@onready var tileset: TileMapLayer = $Collectibles
@onready var pause_scene = preload("res://scenes/ui/PauseMenu.tscn")
@onready var pause_inst
# Node references
@onready var player_start: Marker2D = $PlayerStart
@onready var props_container: Node2D = $Props
var paused = false
var player
func _ready() -> void:
	pause_inst = pause_scene.instantiate()
	add_child(pause_inst)
	pause_inst.hide()
	# Setup level
	_initialize_level()
	
	# Spawn player
	_spawn_player()
	
	# Count fireflies if auto-count enabled
	if auto_count_fireflies:
		_count_fireflies()
	
	# Configure GameManager
	if GameManager:
		GameManager.current_level_name = level_name
		GameManager.set_total_fireflies(total_fireflies_in_level)
		
		if time_limit > 0:
			GameManager.start_timer(time_limit)
	
	# TODO: Play level music
	# TODO: Level-specific setup (whirlpool pairs, etc.)

func _initialize_level() -> void:
	"""Level-specific initialization."""
	# Override in level-specific scripts if needed
	pass

func _spawn_player() -> void:
	"""Spawn player at PlayerStart position."""
	var player_scene = preload("res://scenes/prefabs/Player.tscn")
	player = player_scene.instantiate()
	
	if player_start:
		player.global_position = player_start.global_position
	else:
		player.global_position = Vector2(32, 32)  # Default position
	
	add_child(player)
	
	# TODO: Add camera follow to player if needed
	# var camera = Camera2D.new()
	# player.add_child(camera)
	# camera.enabled = true

func _count_fireflies() -> void:
	"""Count total fireflies in level for GameManager."""
	var fireflies = get_tree().get_nodes_in_group("Collectible")
	total_fireflies_in_level = fireflies.size()
	
	if GameManager:
		GameManager.set_total_fireflies(total_fireflies_in_level)

func get_whirlpool_pairs() -> Dictionary:
	"""
	Return dictionary of whirlpool pairs for this level.
	Override in level-specific scripts to define pairs.
	Format: {"pair_1": [whirlpool_a, whirlpool_b], ...}
	"""
	return {}

func _process(_delta):
	
	if Input.is_action_just_pressed("pause") and paused == false:
		pause_inst.show()
		get_tree().paused = true
		player.hide()
		paused = true
		
	elif Input.is_action_just_pressed("pause") and paused == true:
		pause_inst.hide()
		get_tree().paused = false
		player.show()
		paused = false
# Helper functions for level design
#
#func add_firefly_at(pos: Vector2) -> void:
	#"""Add firefly at position (useful for testing)."""
	#var firefly_scene = preload("res://scenes/prefabs/Firefly.tscn")
	#var firefly = firefly_scene.instantiate()
	#firefly.global_position = pos
	#props_container.add_child(firefly) if props_container else add_child(firefly)
#
#func add_obstacle_at(pos: Vector2, type: String = "rock") -> void:
	#"""Add obstacle at position."""
	#var obstacle_scene
	#match type:
		#"rock":
			#obstacle_scene = preload("res://scenes/prefabs/RockTile.tscn")
		#_:
			#push_warning("Unknown obstacle type: " + type)
			#return
	#
	#var obstacle = obstacle_scene.instantiate()
	#obstacle.global_position = pos
	#props_container.add_child(obstacle) if props_container else add_child(obstacle)
