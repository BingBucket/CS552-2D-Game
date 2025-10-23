extends Area2D
class_name CattailTile

# Cattail serves as grapple anchor point for player's tongue

@export var attach_point_offset: Vector2 = Vector2(0, -8)  # Offset from center for grapple attachment
@export var can_grapple: bool = true

# Signals
signal grapple_anchored(by: Node)
signal grapple_released(by: Node)

# State
var grappled_by: Node = null

# Node references
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	add_to_group("Anchor")
	# Configure collision for grapple detection
	# Layer 16 (bit 4) for anchors, detected by GrappleSensor
	collision_layer = 16
	collision_mask = 0
	
	# TODO: Could add visual feedback when player is nearby (glow, highlight)

func get_attach_point() -> Vector2:
	"""Return world position where grapple should attach."""
	return global_position + attach_point_offset

func on_grapple_attached(player: Node) -> void:
	"""Called when player attaches grapple to this cattail."""
	if not can_grapple:
		return
	
	grappled_by = player
	grapple_anchored.emit(player)
	
	# TODO: Play cattail/grapple sfx 
	# TODO: Visual feedback (sway, highlight)
	_start_visual_feedback()

func on_grapple_released(player: Node) -> void:
	"""Called when player releases grapple."""
	if grappled_by == player:
		grappled_by = null
		grapple_released.emit(player)
		_stop_visual_feedback()

func _start_visual_feedback() -> void:
	"""Visual effect when grappled."""
	# TODO: Tween sprite scale or rotation
	# var tween = create_tween()
	# tween.tween_property(sprite, "scale", Vector2(1.1, 0.9), 0.1)
	# tween.tween_property(sprite, "scale", Vector2.ONE, 0.2)
	pass

func _stop_visual_feedback() -> void:
	"""Stop visual effect."""
	# TODO: Reset sprite properties
	pass

func disable_grapple() -> void:
	"""Temporarily disable grappling (for puzzles)."""
	can_grapple = false
	# TODO: Visual indicator (grey out, etc.)

func enable_grapple() -> void:
	"""Re-enable grappling."""
	can_grapple = true
	# TODO: Restore normal appearance
