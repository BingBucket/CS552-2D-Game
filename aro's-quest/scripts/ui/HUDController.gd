extends CanvasLayer
class_name HUDController

# HUD displays game state: health, fireflies, timer, level name

# Node references
@onready var level_text: Label = $HUDContainer/TopBar/LevelText
@onready var timer_label: Label = $HUDContainer/TopBar/TimerLabel
@onready var heart_display: HBoxContainer = $HUDContainer/TopBar/HeartDisplay
@onready var firefly_counter: Label = $HUDContainer/TopBar/FireflyCounter

# Heart icons (created dynamically)
var heart_icons: Array[TextureRect] = []

func _ready() -> void:
	# Connect to GameManager signals
	if GameManager:
		GameManager.fireflies_changed.connect(_on_fireflies_changed)
		GameManager.life_changed.connect(_on_life_changed)
		GameManager.timer_changed.connect(_on_timer_changed)
		GameManager.level_completed.connect(_on_level_completed)
		GameManager.level_failed.connect(_on_level_failed)
	
	# Initialize displays
	_setup_hearts(3)  # Default 3 hearts
	update_fireflies(0, 0)
	update_timer(0)
	
	# TODO: Load heart textures
	# TODO: Setup styles and themes

func update_hearts(current: int, max_hearts: int) -> void:
	"""Update heart display."""
	# Ensure we have correct number of heart icons
	if heart_icons.size() != max_hearts:
		_setup_hearts(max_hearts)
	
	# Update each heart's appearance
	for i in range(heart_icons.size()):
		if i < current:
			# Full heart
			heart_icons[i].modulate = Color.WHITE
			# TODO: Set to full heart texture
		else:
			# Empty heart
			heart_icons[i].modulate = Color(0.3, 0.3, 0.3, 0.5)
			# TODO: Set to empty heart texture

func update_timer(time_left: float) -> void:
	"""Update timer display."""
	if not timer_label:
		return
	
	if time_left <= 0:
		timer_label.text = ""
		timer_label.visible = false
		return
	
	timer_label.visible = true
	var minutes = int(time_left) / 60
	var seconds = int(time_left) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	# Warning color when low on time
	if time_left < 10:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif time_left < 30:
		timer_label.add_theme_color_override("font_color", Color.YELLOW)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)

func update_fireflies(current: int, required: int) -> void:
	"""Update firefly counter display."""
	if not firefly_counter:
		return
	
	if required > 0:
		firefly_counter.text = "Fireflies: %d / %d" % [current, required]
	else:
		firefly_counter.text = "Fireflies: %d" % current
	
	# Color feedback
	if required > 0 and current >= required:
		firefly_counter.add_theme_color_override("font_color", Color.GREEN)
	else:
		firefly_counter.add_theme_color_override("font_color", Color.WHITE)

func update_level_name(level_name: String) -> void:
	"""Update level name display."""
	if level_text:
		level_text.text = level_name

func _setup_hearts(count: int) -> void:
	"""Create heart icon sprites."""
	if not heart_display:
		return
	
	# Clear existing hearts
	for heart in heart_icons:
		heart.queue_free()
	heart_icons.clear()
	
	# Create new hearts
	for i in range(count):
		var heart = TextureRect.new()
		heart.custom_minimum_size = Vector2(16, 16)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# TODO: Set heart texture
		# heart.texture = preload("res://sprites/heart.png")
		heart_display.add_child(heart)
		heart_icons.append(heart)

func _on_fireflies_changed(count: int) -> void:
	"""Called when GameManager firefly count changes."""
	var required = GameManager.total_fireflies if GameManager else 0
	update_fireflies(count, required)

func _on_life_changed(lives: int) -> void:
	"""Called when GameManager life count changes."""
	# Lives are typically player hearts
	var max_hearts = GameManager.max_hearts if GameManager and GameManager.has("max_hearts") else 3
	update_hearts(lives, max_hearts)

func _on_timer_changed(time_left: float) -> void:
	"""Called when GameManager timer updates."""
	update_timer(time_left)

func _on_level_completed(level_name: String) -> void:
	"""Called when level is completed."""
	# TODO: Show completion message or animation
	pass

func _on_level_failed(level_name: String) -> void:
	"""Called when level is failed."""
	# TODO: Show failure message
	pass

func show_message(message: String, duration: float = 2.0) -> void:
	"""Display temporary message on HUD."""
	# TODO: Create or show message label
	# TODO: Auto-hide after duration
	print("HUD Message: " + message)
