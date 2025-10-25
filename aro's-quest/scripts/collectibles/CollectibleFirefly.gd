extends Area2D
class_name CollectibleFirefly

# Firefly collectible - main collectible for the game

@export var value: int = 1
@export var float_animation: bool = true
@export var float_height: float = 4.0
@export var float_speed: float = 2.0

# Signals
signal collected(by: Node)

# State
var is_collected: bool = false
var initial_position: Vector2

# Node references
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audioplayer: AudioStreamPlayer = $AudioStreamPlayer
func _ready() -> void:
	add_to_group("Collectible")
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	
	# Store initial position for floating animation
	initial_position = position
	
	# TODO: Start glow/pulse animation
	sprite.play("default")

func _process(delta: float) -> void:
	"""Floating animation."""
	if float_animation and not is_collected:
		var time = Time.get_ticks_msec() * 0.001 * float_speed
		position.y = initial_position.y + sin(time) * float_height

func _on_area_entered(area: Area2D) -> void:
	"""Detect player collection."""
	if area.is_in_group("Player") or area.get_parent().is_in_group("Player"):
		_collect(area)

func _collect(collector: Node) -> void:
	"""Handle collection."""
	if is_collected:
		return
	
	is_collected = true
	
	# Add to GameManager
	if GameManager:
		GameManager.add_fireflies(value)
	
	# Emit signal
	var player = collector if collector.is_in_group("Player") else collector.get_parent()
	collected.emit(player)
	
	# TODO: Play collection sound
	# TODO: Collection particle effect
	audioplayer.play()
	sprite.play("collected")
	await get_tree().create_timer(0.75).timeout
	sprite.hide()
	

func _start_idle_animation() -> void:
	"""Idle glow/pulse effect."""
	# TODO: Modulate alpha or scale
	# var tween = create_tween()
	# tween.set_loops()
	# tween.tween_property(sprite, "modulate:a", 0.6, 0.8)
	# tween.tween_property(sprite, "modulate:a", 1.0, 0.8)
	pass


func _on_body_entered(body: Node2D) -> void:
	"""Detect player collection."""
	if body.is_in_group("Player") or body.get_parent().is_in_group("Player"):
		_collect(body)
