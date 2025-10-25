extends Control
class_name MenuController

# Generic menu controller for MainMenu, PauseMenu, Win/Lose screens

@export var menu_type: String = "main"  # "main", "pause", "win", "lose"

# Common buttons (not all menus have all buttons)
@onready var start_button: Button = $ColorRect/VBoxContainer/StartButton if has_node("ColorRect/VBoxContainer/StartButton") else null
@onready var resume_button: Button = $ColorRect/VBoxContainer/ResumeButton if has_node("ColorRect/VBoxContainer/ResumeButton") else null
@onready var restart_button: Button = $ColorRect/VBoxContainer/RestartButton if has_node("ColorRect/VBoxContainer/RestartButton") else null
@onready var next_level_button: Button = $ColorRect/VBoxContainer/NextLevelButton if has_node("ColorRect/VBoxContainer/NextLevelButton") else null
@onready var settings_button: Button = $ColorRect/VBoxContainer/SettingsButton if has_node("ColorRect/VBoxContainer/SettingsButton") else null
@onready var main_menu_button: Button = $ColorRect/VBoxContainer/MainMenuButton if has_node("ColorRect/VBoxContainer/MainMenuButton") else null
@onready var quit_button: Button = $ColorRect/VBoxContainer/QuitButton if has_node("ColorRect/VBoxContainer/QuitButton") else null
@onready var timer_label: Label = $ColorRect/VBoxContainer/TimerLabel if has_node("ColorRect/VBoxContainer/TimerLabel") else null
@onready var final_timer_label: Label = $ColorRect/VBoxContainer/FinalTimerLabel if has_node("ColorRect/VBoxContainer/TimerLabel") else null
func _ready() -> void:
	# Connect buttons that exist
	if start_button:
		start_button.pressed.connect(start_game)
	if resume_button:
		resume_button.pressed.connect(resume_game)
	if restart_button:
		restart_button.pressed.connect(restart_level)
	if next_level_button:
		next_level_button.pressed.connect(next_level)
	if settings_button:
		settings_button.pressed.connect(open_settings)
	if main_menu_button:
		main_menu_button.pressed.connect(go_to_main_menu)
	if quit_button:
		quit_button.pressed.connect(quit_game)
	if timer_label:
		timer_label.text = "Time: " + GameManager.play_time
	if final_timer_label:
		final_timer_label.text = "Time: " + GameManager.final_time
	# Setup based on menu type
	_setup_menu()
	print(global_position)

func update_text():
	print("Signal received")
	timer_label.text = GameManager.play_time
func _setup_menu() -> void:
	"""Initialize menu based on type."""
	match menu_type:
		"pause":
			# Pause menu specific setup
			show()
		"win":
			# Victory screen setup
			# TODO: Show stats, time, fireflies collected
			pass
		"lose":
			# Game over screen setup
			pass

func start_game() -> void:
	"""Start new game from main menu."""
	# Play UI click sound
	if GameManager:
		GameManager.current_level_number = 1
		GameManager.load_level("res://scenes/levels/level_1.tscn")
	else:
		# Fallback: load first level
		get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")

func resume_game() -> void:
	"""Resume from pause menu."""
	get_tree().paused = false
	hide()  # Remove pause menu

func restart_level() -> void:
	"""Restart current level."""
	get_tree().paused = false
	if GameManager:
		GameManager.restart_level()
	else:
		get_tree().reload_current_scene()

func next_level() -> void:
	print("next")
	"""Go to next level (from win screen)."""
	if GameManager:
		print("exists")
		GameManager.next_level()
	else:
		push_warning("GameManager not available for level progression")
		print("nuh uh")

func open_settings() -> void:
	"""Open settings menu."""
	# TODO: Load settings scene
	# var settings = preload("res://scenes/ui/Settings.tscn").instantiate()
	# get_tree().current_scene.add_child(settings)
	print("Settings menu not implemented")

func go_to_main_menu() -> void:
	"""Return to main menu."""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func quit_game() -> void:
	"""Quit application."""
	get_tree().quit()

func show_menu() -> void:
	"""Show this menu."""
	visible = true
	if menu_type == "pause":
		get_tree().paused = true

func hide_menu() -> void:
	"""Hide this menu."""
	visible = false
	if menu_type == "pause":
		get_tree().paused = false
