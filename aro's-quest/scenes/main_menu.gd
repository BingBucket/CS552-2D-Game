extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var ui_sfx: AudioStreamPlayer = $UIClickSFX

func _ready() -> void:
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Play menu music
	if music_player and music_player.stream:
		music_player.play()
	
	# Add hover effects
	start_button.mouse_entered.connect(_on_button_hover.bind(start_button))
	quit_button.mouse_entered.connect(_on_button_hover.bind(quit_button))

func _on_start_pressed() -> void:
	# Play UI click sound
	if ui_sfx and ui_sfx.stream:
		ui_sfx.play()
		await ui_sfx.finished
	
	# Load first level
	get_tree().change_scene_to_file("res://scenes/levels/level_1.tscn")

func _on_quit_pressed() -> void:
	# Play UI click sound
	if ui_sfx and ui_sfx.stream:
		ui_sfx.play()
		await ui_sfx.finished
	
	# Quit game
	get_tree().quit()

func _on_button_hover(button: Button) -> void:
	# Simple hover effect
	button.modulate = Color(1.2, 1.2, 1.2)
	await button.mouse_exited
	button.modulate = Color.WHITE
