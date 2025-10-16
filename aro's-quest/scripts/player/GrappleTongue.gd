extends Node2D
class_name GrappleTongue

# Grapple parameters
@export var max_range: float = 160.0
@export var attach_speed: float = 200.0
@export var pull_strength: float = 300.0
@export var swing_enabled: bool = true  # Use physics joint vs. direct pull

# Signals
signal attached(anchor: Node2D)
signal detached()

# State
var is_attached: bool = false
var anchor_node: Node2D = null
var attach_point: Vector2 = Vector2.ZERO

# Node references
@onready var grapple_ray: RayCast2D = $GrappleRay
@onready var grapple_area: Area2D = $GrappleArea
@onready var grapple_line: Line2D = $GrappleLine
@onready var player: CharacterBody2D = get_parent()

# Optional physics joint for swinging
var joint: PinJoint2D = null

func _ready() -> void:
	grapple_line.clear_points()
	# TODO: Configure collision layers for grapple detection
	# grapple_area should detect layer 16 (Anchors group)

func _physics_process(delta: float) -> void:
	if is_attached and anchor_node:
		_update_grapple_line()
		
		if swing_enabled:
			_apply_swing_physics(delta)
		else:
			_apply_pull_physics(delta)

func try_grapple(target_direction: Vector2) -> void:
	"""
	Attempt to grapple in the given direction.
	Use Area2D approach for 16x16 tile grid simplicity.
	"""
	if is_attached:
		return

	# Area detection
	var anchors = grapple_area.get_overlapping_areas()
	var closest_anchor: Area2D = null
	var closest_dist: float = max_range + 1.0
	
	for anchor in anchors:
		if anchor.is_in_group("Anchor"):
			var dist = global_position.distance_to(anchor.global_position)
			if dist < closest_dist and dist <= max_range:
				closest_dist = dist
				closest_anchor = anchor
	
	if closest_anchor:
		attach_to(closest_anchor)

func attach_to(anchor: Node2D) -> void:
	"""Attach grapple to anchor point."""
	if is_attached:
		return
	
	is_attached = true
	anchor_node = anchor
	
	# Get attach point from Cattail if it has one
	if anchor.has_method("get_attach_point"):
		attach_point = anchor.get_attach_point()
	else:
		attach_point = anchor.global_position
	
	# Option A: Create physics joint for realistic swinging
	if swing_enabled:
		_create_swing_joint()
	
	# Emit signal
	attached.emit(anchor_node)
	
	# TODO: Play grapple attach sound
	# TODO: Start grapple attach animation

func release() -> void:
	"""Detach grapple and return to normal movement."""
	if not is_attached:
		return
	
	is_attached = false
	
	# Remove physics joint if exists
	if joint:
		joint.queue_free()
		joint = null
	
	# Clear visual line
	grapple_line.clear_points()
	
	# Reset anchor
	anchor_node = null
	
	# Emit signal
	detached.emit()
	
	# TODO: Play grapple release sound

func _create_swing_joint() -> void:
	"""
	Create a PinJoint2D for physics-based swinging.
	"""
	# Create a static body at attach point for joint anchor
	var static_anchor = StaticBody2D.new()
	static_anchor.global_position = attach_point
	get_tree().current_scene.add_child(static_anchor)
	
	# Create pin joint
	joint = PinJoint2D.new()
	joint.global_position = attach_point
	joint.node_a = static_anchor.get_path()
	joint.node_b = player.get_path()
	joint.softness = 0.1  # Slight elasticity
	get_tree().current_scene.add_child(joint)
	
	# Store reference to clean up static anchor
	joint.set_meta("static_anchor", static_anchor)

func _apply_swing_physics(delta: float) -> void:
	"""
	Physics-based swinging using joint.
	Joint handles the physics, this just maintains rope tension.
	"""
	# The PinJoint2D handles the physics automatically
	pass

func _apply_pull_physics(delta: float) -> void:
	"""
	Manual pull approach (simpler, less realistic).
	Directly modify player velocity to pull toward anchor.
	"""
	if not player:
		return
	
	var direction = (attach_point - player.global_position).normalized()
	var distance = player.global_position.distance_to(attach_point)
	
	# Pull player toward anchor
	var pull_velocity = direction * pull_strength
	player.velocity += pull_velocity * delta
	
	# Stop pulling when close enough
	if distance < 16.0:  # One tile distance
		release()

func _update_grapple_line() -> void:
	"""Draw Line2D from player to anchor point."""
	grapple_line.clear_points()
	if is_attached and anchor_node:
		# Draw from player mouth/center to attach point
		grapple_line.add_point(Vector2.ZERO)  # Local to this node
		grapple_line.add_point(to_local(attach_point))

func _exit_tree() -> void:
	"""Cleanup on removal."""
	if joint:
		if joint.has_meta("static_anchor"):
			var static_anchor = joint.get_meta("static_anchor")
			static_anchor.queue_free()
		joint.queue_free()
