extends CharacterBody2D
class_name PlayerController

# Player is STATIONARY - only rotates to aim grapple
# Movement comes from water currents and grappling

@export var max_hearts: int = 3
@export var snapped_current_tile = false
# Signals
signal collected_firefly(count: int)
signal hurt(amount: int)
signal died()
signal grapple_attached(anchor_node: Node)
signal grapple_released()

# Internal state
var current_hearts: int = 3
var is_grappling: bool = false
var external_velocity: Vector2 = Vector2.ZERO  # For water currents
var facing_direction: Vector2 = Vector2.RIGHT
var rotation_angle: int = 0  # 0=right, 90=down, 180=left, 270=up (in degrees)
var rope_attached: bool = false
var rope_anchor: Vector2 = Vector2.ZERO
var rope_length: float = 0.0
@export var rope_softness: float = 0.15  # 0 = rigid, higher = softer
@export var rope_max_length_scale: float = 1.0  # keep length fixed (1.0)

# Node references (set in _ready)
@onready var sprite: Sprite2D = $Sprite
@onready var grapple_sensor: Area2D = $GrappleSensor
@onready var grapple_line: Line2D = $GrappleLine
@onready var grapple_point: Node2D = $GrapplePoint
@onready var health_system = $Components/HealthSystem  # Optional if HealthSystem is separate
@onready var player = $AudioStreamPlayer

func _ready() -> void:
	add_to_group("Player")
	current_hearts = max_hearts
	
	# Connect to HealthSystem if it exists
	if has_node("Components/HealthSystem"):
		var health = get_node("Components/HealthSystem")
		health.health_changed.connect(_on_health_changed)
		health.died.connect(_on_died)
	
	# Initialize facing right
	_set_rotation_from_input(Vector2.RIGHT)
	
	# TODO: Setup animations when AnimatedSprite2D is added

func _physics_process(delta: float) -> void:
	
	# Base velocity
	if rope_attached:
		# When grappled, IGNORE water current completely
		# Preserve existing velocity to keep momentum around the anchor
		pass
	else:
		# When not grappled, water tiles set external_velocity
		velocity = external_velocity

	# If rope is attached, enforce distance constraint to swing around anchor
	if rope_attached:
		var to_anchor = rope_anchor - global_position
		var dist = to_anchor.length()
		if dist > 0.0:
			var dir = to_anchor / dist
			# Corrective velocity to keep distance near rope_length
			var excess = dist - rope_length
			# Apply a spring-like correction along the rope direction only
			velocity += dir * (excess / max(rope_length, 0.001)) * rope_softness * 300.0
			# Remove radial component that would increase length beyond rope
			var radial_speed = velocity.dot(dir)
			if dist >= rope_length and radial_speed > 0.0:
				# Cancel outward radial speed to prevent stretching
				velocity -= dir * radial_speed

		# Draw rope line
		if grapple_line:
			grapple_line.clear_points()
			grapple_line.add_point(Vector2.ZERO)
			grapple_line.add_point(to_local(rope_anchor))
	else:
		if grapple_line:
			grapple_line.clear_points()

	move_and_slide()

	# Reset AFTER movement so next frame starts clean
	if rope_attached:
		# Ignore water while attached
		external_velocity = Vector2.ZERO
	else:
		external_velocity = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	# Handle rotation with arrow keys / WASD
	if event.is_action_pressed("right"):
		_rotate_to_direction(Vector2.RIGHT)
	elif event.is_action_pressed("left"):
		_rotate_to_direction(Vector2.LEFT)
	elif event.is_action_pressed("up"):
		_rotate_to_direction(Vector2.UP)
	elif event.is_action_pressed("down"):
		_rotate_to_direction(Vector2.DOWN)
	
	# Grapple input (hold to stay attached)
	if event.is_action_pressed("grapple"):
		if not rope_attached:
			attempt_grapple()
	elif event.is_action_released("grapple"):
		if rope_attached:
			release_grapple()

func _rotate_to_direction(direction: Vector2) -> void:
	"""Rotate player to face one of 4 cardinal directions (90° intervals)."""
	facing_direction = direction
	_set_rotation_from_input(direction)

func _set_rotation_from_input(direction: Vector2) -> void:
	"""Set sprite rotation based on facing direction."""
	if direction == Vector2.RIGHT:
		rotation_degrees = 0
		rotation_angle = 0
	elif direction == Vector2.DOWN:
		rotation_degrees = 90
		rotation_angle = 90
	elif direction == Vector2.LEFT:
		rotation_degrees = 180
		rotation_angle = 180
	elif direction == Vector2.UP:
		rotation_degrees = 270
		rotation_angle = 270

func attempt_grapple() -> void:
	"""Try to grapple to nearest anchor (Cattail) in facing direction."""
	var anchors = grapple_sensor.get_overlapping_areas()
	
	# Find closest anchor in the direction we're facing
	var closest_anchor: Area2D = null
	var closest_dist: float = 999999.0
	
	for anchor in anchors:
		if anchor.is_in_group("Anchor"):
			# Check if anchor is roughly in the direction we're facing
			var to_anchor = (anchor.global_position - global_position).normalized()
			var dot = to_anchor.dot(facing_direction)
			
			# Only consider anchors in front of us (dot > 0.5 means roughly same direction)
			if dot > 0.5:
				var dist = global_position.distance_to(anchor.global_position)
				if dist < closest_dist:
					closest_dist = dist
					closest_anchor = anchor
	
	if closest_anchor:
		start_grapple(closest_anchor)

func start_grapple(anchor: Node2D) -> void:
	"""Begin grappling to anchor point."""
	player.play()
	is_grappling = true
	rope_attached = true
	rope_anchor = anchor.global_position if anchor else global_position
	rope_length = global_position.distance_to(rope_anchor) * rope_max_length_scale
	grapple_attached.emit(anchor)

func release_grapple() -> void:
	"""Release grapple and return to normal movement."""
	is_grappling = false
	rope_attached = false
	grapple_released.emit()
	if grapple_line:
		grapple_line.clear_points()

func take_damage(amount: int = 1) -> void:
	"""Take damage and emit signals."""
	hurt.emit(amount)
	# If using HealthSystem component, delegate to it
	if has_node("Components/HealthSystem"):
		get_node("Components/HealthSystem").take_damage(amount)
	else:
		current_hearts -= amount
		if current_hearts <= 0:
			die()

func die() -> void:
	"""Handle player death."""
	died.emit()
	GameManager.lose_life()
	# TODO: Play death animation
	# TODO: Disable input

func _on_health_changed(current: int) -> void:
	"""Called when HealthSystem health changes."""
	current_hearts = current

func _on_died() -> void:
	"""Called when HealthSystem triggers death."""
	die()

func apply_external_velocity(vel: Vector2) -> void:
	"""Apply external force like water current."""
	external_velocity += vel

# Collision handling
func _on_area_entered(area: Area2D) -> void:
	"""Handle area collisions (collectibles, triggers, etc.)."""
	# Collectibles and triggers handle their own logic
	# This is here for optional additional player-side logic
	pass

func _on_body_entered(body: Node) -> void:
	"""Handle body collisions (obstacles, etc.)."""
	if body.is_in_group("Obstacle"):
		# Hit a rock or obstacle
		take_damage(1)
		# TODO: Add knockback or bounce effect
