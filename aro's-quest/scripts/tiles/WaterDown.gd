extends Node2D

# Water tile that applies current force to player
# Use Area2D to detect player and apply velocity

@export var current_direction: Vector2 = Vector2.DOWN # Should be normalized
@export var speed: float = 80.0
@export var visual_flow_speed: float = 1.0  # For animated water texture
# Node references
@onready var current_area: Area2D = $CurrentArea
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var variant_name: String = ""
# set with tile instance id
var key = "snapped_current_tile_%d" % self.get_instance_id()
# Bodies currently in water
var bodies_in_current: Array[Node] = []

func _ready() -> void:
	add_to_group("Water")
	
	# Process BEFORE player to ensure velocity is set before player moves
	process_physics_priority = -10
	# Normalize direction
	current_direction = current_direction.normalized()
	
	# Connect area signals
	if current_area:
		current_area.area_entered.connect(_on_area_entered)
		current_area.area_exited.connect(_on_area_exited)
		current_area.body_entered.connect(_on_body_entered)
		current_area.body_exited.connect(_on_body_exited)
	
	# Start water animation
	if sprite:
		sprite.play("default")

#func _read_tileset_metadata() -> void:
	#var tilemap := _find_parent_tilemap()
	#if not tilemap:
		#return
	#var cell = tilemap.local_to_map(global_position)
	#var tile_id = tilemap.get_cell_tile_data(cell)
	#var meta = tilemap.tile_set.tile_get_metadata(tile_id)
	#print(cell)
	#print(tile_id)
	#print(meta)
	#
#func _find_parent_tilemap() -> TileMapLayer:
	#var node:= get_parent()
	#while node:
		#if node is TileMapLayer:
			#return node
		#node = node.get_parent()
	#return null
func _physics_process(delta: float) -> void:
	"""
	Apply current to all bodies in the water.
	Set external_velocity on player (simpler for CharacterBody2D)
	"""
	for body in bodies_in_current:
		apply_current_to(body)

func apply_current_to(body: Node) -> void:
	"""Apply water current to a body."""
	await get_tree().create_timer(0.2).timeout
	if not is_instance_valid(body):
		return
	
	# For CharacterBody2D - SET velocity, don't add to it
	if body.has_method("apply_external_velocity"):
		body.apply_external_velocity(current_direction * speed)
	elif body.has("external_velocity"):
		body.external_velocity = current_direction * speed  # Changed from += to =
	

func _on_area_entered(area: Area2D) -> void:
	"""Detect when Area2D enters (player grapple sensor, etc.)."""
	var parent = area.get_parent()
	if parent and parent.is_in_group("Player"):
		if parent not in bodies_in_current:
			bodies_in_current.append(parent)
		# TODO: Play water splash sound

func _on_area_exited(area: Area2D) -> void:
	"""Detect when Area2D exits."""
	var parent = area.get_parent()
	if parent in bodies_in_current:
		bodies_in_current.erase(parent)

func _on_body_entered(body: Node) -> void:
	"""Detect when CharacterBody2D or RigidBody2D enters."""
	if body.is_in_group("Player") and body not in bodies_in_current:
		bodies_in_current.append(body)

func _on_body_exited(body: Node) -> void:
	"""Detect when body exits."""
	if body in bodies_in_current:
		bodies_in_current.erase(body)

func set_flow_direction(direction: Vector2) -> void:
	"""Change current direction at runtime."""
	current_direction = direction.normalized()
	# TODO: Update sprite rotation or animation to match flow

# Optional: Visual flow animation
func _process(delta: float) -> void:
	"""Animate water texture scrolling."""
	# TODO: Scroll texture or shader offset
	# if sprite and sprite.material:
	#     sprite.material.set_shader_parameter("offset", Time.get_ticks_msec() * 0.001 * visual_flow_speed)
	pass
