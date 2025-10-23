extends Node

# GameManager - Autoload singleton for global game state
# Manages levels, lives, collectibles, timer, and transitions

## Level Management
var current_level_name: String = ""
var current_level_number: int = 1
var max_level: int = 5  # Total levels in game

## Player Stats
var lives: int = 3
var max_lives: int = 3
var max_hearts: int = 3  # For health system

## Collectibles
var fireflies_collected: int = 0
var total_fireflies: int = 0  # Set by level when loaded

## Timer
var level_time_limit: float = 0.0  # 0 = no time limit
var time_remaining: float = 0.0
var timer_active: bool = false
#play_time during a level
var play_time: String = ''

## Whirlpool Registry
var whirlpool_pairs: Dictionary = {}  # pair_id -> Array[WhirlpoolPortal]

## Signals
signal level_completed(level_name: String)
signal level_failed(level_name: String)
signal fireflies_changed(count: int)
signal life_changed(lives: int)
signal timer_changed(time_left: float)
signal game_over()
signal game_won()

func _ready() -> void:
	# Initialize game state
	reset_game_state()

func _process(delta: float) -> void:
	# Update timer if active
	if timer_active and level_time_limit > 0:
		time_remaining -= delta
		timer_changed.emit(time_remaining)
		
		if time_remaining <= 0:
			time_remaining = 0
			_on_time_expired()

## Level Management

func load_level(level_path: String) -> void:
	"""Load a specific level by path."""
	reset_level_state()
	current_level_name = level_path.get_file().get_basename()
	get_tree().change_scene_to_file(level_path)

func restart_level() -> void:
	"""Restart current level."""
	reset_level_state()
	get_tree().reload_current_scene()

func next_level() -> void:
	"""Progress to next level."""
	current_level_number += 1
	
	if current_level_number > max_level:
		# Game completed!
		_complete_game()
		return
	
	# Load next level
	var next_level_path = "res://scenes/levels/level_%d.tscn" % current_level_number
	if ResourceLoader.exists(next_level_path):
		load_level(next_level_path)
	else:
		push_warning("Next level not found: " + next_level_path)
		_complete_game()

func try_complete_level() -> bool:
	"""
	Attempt to complete current level.
	Returns true if successful, false if requirements not met.
	"""
	# Check firefly requirement
	if total_fireflies > 0 and fireflies_collected < total_fireflies:
		return false
	
	# Check timer requirement
	if level_time_limit > 0 and time_remaining <= 0:
		return false
	
	# Level completed!
	_level_complete()
	return true

func _level_complete() -> void:
	"""Handle successful level completion."""
	level_completed.emit(current_level_name)
	timer_active = false
	
	# TODO: Play victory sound
	# TODO: Calculate score ?
	
	# Show win screen
	_show_win_screen()

func _level_fail() -> void:
	"""Handle level failure."""
	level_failed.emit(current_level_name)
	timer_active = false
	
	# TODO: Play failure sound
	
	# Show lose screen or restart
	if lives > 0:
		restart_level()
	else:
		_show_game_over()

func _complete_game() -> void:
	"""Handle completing all levels."""
	game_won.emit()
	# TODO: Show final victory screen with total stats
	print("Congratulations! Game completed!")

## Life Management

func lose_life(amount: int = 1) -> void:
	"""Lose lives and handle game over."""
	lives -= amount
	lives = max(0, lives)
	life_changed.emit(lives)
	
	if lives <= 0:
		_show_game_over()
	else:
		# Restart level with remaining lives
		restart_level()


## Firefly Management

func add_fireflies(amount: int) -> void:
	"""Add collected fireflies."""
	fireflies_collected += amount
	fireflies_changed.emit(fireflies_collected)
	
	# TODO: Play collection jingle
	# TODO: Check if goal should activate

func set_total_fireflies(count: int) -> void:
	"""Set total fireflies for current level (called by level script)."""
	total_fireflies = count
	fireflies_changed.emit(fireflies_collected)

## Timer Management

func start_timer(duration: float) -> void:
	"""Start level timer with given duration."""
	level_time_limit = duration
	time_remaining = duration
	timer_active = true
	timer_changed.emit(time_remaining)

func stop_timer() -> void:
	"""Stop the timer."""
	timer_active = false

func _on_time_expired() -> void:
	"""Called when timer reaches zero."""
	timer_active = false
	# Time's up - level failed
	_level_fail()

## Whirlpool Management

func register_whirlpool(pair_id: String, whirlpool: Node) -> void:
	"""Register a whirlpool with its pair ID."""
	if not whirlpool_pairs.has(pair_id):
		whirlpool_pairs[pair_id] = []
	
	if whirlpool not in whirlpool_pairs[pair_id]:
		whirlpool_pairs[pair_id].append(whirlpool)

func get_whirlpool_target(pair_id: String, source_whirlpool: Node) -> Node:
	"""Get the paired whirlpool for teleportation."""
	if not whirlpool_pairs.has(pair_id):
		return null
	
	var pair = whirlpool_pairs[pair_id]
	for whirlpool in pair:
		if whirlpool != source_whirlpool and is_instance_valid(whirlpool):
			return whirlpool
	
	return null

func clear_whirlpool_registry() -> void:
	"""Clear whirlpool registry (called on level change)."""
	whirlpool_pairs.clear()

## State Management

func reset_level_state() -> void:
	"""Reset state for level restart."""
	fireflies_collected = 0
	total_fireflies = 0
	time_remaining = 0
	level_time_limit = 0
	timer_active = false
	clear_whirlpool_registry()
	
	# Emit state changes
	fireflies_changed.emit(fireflies_collected)
	timer_changed.emit(time_remaining)

func reset_game_state() -> void:
	"""Reset entire game state (new game)."""
	lives = max_lives
	current_level_number = 1
	current_level_name = ""
	reset_level_state()
	
	life_changed.emit(lives)

## UI Management

func _show_win_screen() -> void:
	"""Show level completion screen."""
	queue_free()
	var win_scene = preload("res://scenes/ui/Win.tscn")
	var win_screen = win_scene.instantiate()
	get_tree().current_scene.add_child(win_screen)
	
	# TODO: Pass level stats to win screen

func _show_game_over() -> void:
	"""Show game over screen."""
	game_over.emit()
	
	var lose_scene = preload("res://scenes/ui/Lose.tscn")
	var lose_screen = lose_scene.instantiate()
	get_tree().current_scene.add_child(lose_screen)

## Debug Functions

func spawn_test_firefly(pos: Vector2) -> void:
	"""Debug: Spawn firefly at position."""
	var firefly_scene = preload("res://scenes/prefabs/Firefly.tscn")
	var firefly = firefly_scene.instantiate()
	firefly.global_position = pos
	get_tree().current_scene.add_child(firefly)

func teleport_player_to(pos: Vector2) -> void:
	"""Debug: Teleport player to position."""
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.global_position = pos
	else:
		push_warning("Player not found for teleport")

func complete_level_cheat() -> void:
	"""Debug: Instantly complete level."""
	fireflies_collected = total_fireflies
	try_complete_level()

func toggle_invincibility() -> void:
	"""Debug: Toggle player invincibility."""
	# TODO: Set flag on player
	pass
