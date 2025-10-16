extends Area2D
class_name WhirlpoolPortal

# Whirlpool teleports player to paired whirlpool
# Whirlpools must be placed in pairs with matching pair_id

@export var pair_id: String = "portal_1"  # Must match paired whirlpool
@export var teleport_inertia_preserve: bool = true  # Keep player velocity after teleport
@export var teleport_cooldown: float = 0.5  # Prevent immediate re-teleport
@export var stun_duration: float = 0.3  # Brief control disable after teleport

# Signals
signal player_entered(player: Node)
signal player_teleported(player: Node, destination: WhirlpoolPortal)

# State
var teleport_ready: bool = true
var paired_whirlpool: WhirlpoolPortal = null

# Node references
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	add_to_group("Portal")
	
	# Register with GameManager
	if GameManager:
		GameManager.register_whirlpool(pair_id, self)
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# TODO: Start whirlpool spin animation
	_start_spin_animation()

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
	
	# Store velocity before teleport
	var player_velocity = Vector2.ZERO
	if teleport_inertia_preserve and player.has("velocity"):
		player_velocity = player.velocity
	
	# Teleport player
	player.global_position = paired_whirlpool.global_position
	
	# Restore velocity if preserving inertia
	if teleport_inertia_preserve and player.has("velocity"):
		player.velocity = player_velocity
	
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
	var timer = get_tree().create_timer(teleport_cooldown)
	timer.timeout.connect(_reset_teleport)

func _reset_teleport() -> void:
	"""Reset teleport availability."""
	teleport_ready = true

func _start_spin_animation() -> void:
	"""Animate whirlpool spinning."""
	# TODO: Rotate sprite or animate shader
	# var tween = create_tween()
	# tween.set_loops()
	# tween.tween_property(sprite, "rotation", TAU, 2.0)
	pass

func set_pair_id(new_id: String) -> void:
	"""Change pair ID at runtime (for dynamic puzzles)."""
	pair_id = new_id
	paired_whirlpool = null  # Reset cached pair
	
	if GameManager:
		GameManager.register_whirlpool(pair_id, self)
