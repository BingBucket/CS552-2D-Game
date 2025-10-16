extends Node
class_name HealthSystem

# Health parameters
@export var max_hearts: int = 3
@export var invincibility_time: float = 1.0  # Seconds of invincibility after damage

# Signals
signal health_changed(current: int)
signal died()
signal damaged(amount: int)
signal healed(amount: int)

# State
var current_hearts: int = 3
var is_invincible: bool = false

func _ready() -> void:
	current_hearts = max_hearts
	health_changed.emit(current_hearts)

func take_damage(amount: int = 1) -> void:
	"""
	Reduce health by amount.
	Includes invincibility frames to prevent rapid damage.
	"""
	if is_invincible:
		return
	
	current_hearts -= amount
	current_hearts = max(0, current_hearts)
	
	# Emit signals
	damaged.emit(amount)
	health_changed.emit(current_hearts)
	
	# Check for death
	if current_hearts <= 0:
		die()
	else:
		# Start invincibility frames
		_start_invincibility()
	
	# TODO: Play damage sound
	# TODO: Trigger damage animation/flash

func heal(amount: int = 1) -> void:
	"""Restore health up to max."""
	var old_hearts = current_hearts
	current_hearts += amount
	current_hearts = min(current_hearts, max_hearts)
	
	if current_hearts > old_hearts:
		healed.emit(amount)
		health_changed.emit(current_hearts)
		# TODO: Play heal sound

func die() -> void:
	"""Handle death."""
	died.emit()
	# TODO: Play death sound
	# TODO: Death animation
	
	# Call GameManager to handle respawn/game over
	if GameManager:
		GameManager.lose_life()

func reset_health() -> void:
	"""Reset to max health (for level restart)."""
	current_hearts = max_hearts
	is_invincible = false
	health_changed.emit(current_hearts)

func _start_invincibility() -> void:
	"""Start invincibility timer after taking damage."""
	is_invincible = true
	
	# Create timer for invincibility duration
	var timer = get_tree().create_timer(invincibility_time)
	timer.timeout.connect(_end_invincibility)
	
	# TODO: Start visual feedback (flashing sprite)

func _end_invincibility() -> void:
	"""End invincibility period."""
	is_invincible = false
	# TODO: Stop visual feedback

func get_current_hearts() -> int:
	"""Return current health value."""
	return current_hearts

func is_alive() -> bool:
	"""Check if still alive."""
	return current_hearts > 0
