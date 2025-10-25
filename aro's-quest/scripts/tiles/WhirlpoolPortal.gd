extends Area2D
class_name WhirlpoolPortal

# Whirlpool teleports player to paired whirlpool
# Whirlpools must be placed in pairs with matching pair_id

@export var pair_id: String = "portal_1"  # Must match paired whirlpool
@export var teleport_inertia_preserve: bool = true  # Keep player velocity after teleport
@export var teleport_cooldown: float = 0.5  # Prevent immediate re-teleport
@export var stun_duration: float = 0.3  # Brief control disable after teleport
@export var exit_movement_speed: float = 150.0  # Speed to move in entry direction until reaching another tile

# Signals
signal player_entered(player: Node)
signal player_teleported(player: Node, destination: WhirlpoolPortal)

# State
var teleport_ready: bool = true
var paired_whirlpool: WhirlpoolPortal = null
var entry_direction: Vector2 = Vector2.ZERO  # Direction player entered from
var players_in_exit_movement: Array[CharacterBody2D] = []  # Players currently being moved by exit system

# Node references
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("Portal")
	sprite.play()
	# Process BEFORE water tiles to ensure our movement takes priority
	process_physics_priority = -20
	
	# Register with GameManager
	if GameManager:
		GameManager.register_whirlpool(pair_id, self)
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D) -> void:
	"""Detect player via Area2D (grapple sensor, etc.)."""
	var parent = area.get_parent()
	if parent and parent.is_in_group("Player"):
		_attempt_teleport(parent)

func _on_body_entered(body: Node) -> void:
	"""Detect player via CharacterBody2D."""
	if body.is_in_group("Player"):
		_attempt_teleport(body)

func _attempt_teleport(player: Node) -> void:
	"""Try to teleport player to paired whirlpool."""
	if not teleport_ready:
		return
	
	# Find paired whirlpool
	if not paired_whirlpool:
		paired_whirlpool = _find_paired_whirlpool()
	
	if not paired_whirlpool:
		push_warning("Whirlpool %s has no pair with ID: %s" % [name, pair_id])
		return
	
	# Prevent immediate re-teleport
	teleport_ready = false
	paired_whirlpool.teleport_ready = false
	
	# Calculate entry direction (from player to this whirlpool)
	entry_direction = (global_position - player.global_position).normalized()
	
	# Teleport player
	player.global_position = paired_whirlpool.global_position
	
	# Start continuous movement in entry direction until reaching another tile
	if player is CharacterBody2D:
		_start_exit_movement(player)
	
	# Emit signals
	player_entered.emit(player)
	player_teleported.emit(player, paired_whirlpool)
	
	# TODO: Play teleport sound // I need to create this probably
	
	# Apply brief stun to player
	if stun_duration > 0 and player.has_method("set_stunned"):
		player.set_stunned(stun_duration)
	
	# Start cooldown timer
	_start_cooldown_timer()

func _find_paired_whirlpool() -> WhirlpoolPortal:
	"""Find the other whirlpool with matching pair_id."""
	# Query GameManager
	if GameManager and GameManager.has_method("get_whirlpool_target"):
		var target = GameManager.get_whirlpool_target(pair_id, self)
		return target
	
	# Fallback: Search scene tree
	var portals = get_tree().get_nodes_in_group("Portal")
	for portal in portals:
		if portal != self and portal.pair_id == pair_id:
			return portal
	
	return null

func _start_cooldown_timer() -> void:
	"""Start cooldown before portal can be used again."""
	await get_tree().create_timer(teleport_cooldown).timeout
	_reset_teleport()

func _start_exit_movement(player: CharacterBody2D) -> void:
	"""Start continuous movement in entry direction until player reaches another tile."""
	if player not in players_in_exit_movement:
		players_in_exit_movement.append(player)
	
	# Start checking for tile collision
	_start_tile_detection(player)

func _reset_teleport() -> void:
	"""Reset teleport availability."""
	teleport_ready = true
	paired_whirlpool.teleport_ready = true
	if GameManager:
		GameManager.register_whirlpool(pair_id, self)
	

func _start_tile_detection(player: CharacterBody2D) -> void:
	"""Start checking if player has reached another tile."""
	# Use a timer to check periodically
	var timer = get_tree().create_timer(0.1)  # Check every 0.1 seconds
	timer.timeout.connect(_check_tile_reached.bind(player))

func _check_tile_reached(player: CharacterBody2D) -> void:
	"""Check if player has moved far enough from whirlpool to reach another tile."""
	if not player or not is_instance_valid(player):
		players_in_exit_movement.erase(player)
		return
	
	# Check if player is far enough from the exit whirlpool
	var distance_from_exit = player.global_position.distance_to(paired_whirlpool.global_position)
	
	# If player is far enough away, stop the forced movement
	if distance_from_exit > 50.0:  # 50 pixels should be enough to reach another tile
		_stop_exit_movement(player)
		return
	
	# Apply movement using the same system as water tiles
	if player.has_method("apply_external_velocity"):
		player.apply_external_velocity(entry_direction * exit_movement_speed)
	
	# Schedule next check
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(_check_tile_reached.bind(player))

func _stop_exit_movement(player: CharacterBody2D) -> void:
	"""Stop the forced exit movement and let normal game mechanics take over."""
	if player and is_instance_valid(player):
		# Don't set velocity to zero - let water tiles take over naturally
		players_in_exit_movement.erase(player)

func set_pair_id(new_id: String) -> void:
	"""Change pair ID at runtime (for dynamic puzzles)."""
	pair_id = new_id
	paired_whirlpool = null  # Reset cached pair
	
	if GameManager:
		GameManager.register_whirlpool(pair_id, self)
