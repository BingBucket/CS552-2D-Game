extends Area2D
class_name GoalTrigger

# Goal tile - completes level when player reaches it
# Can require collecting all fireflies first

@export var require_all_fireflies: bool = true
@export var required_fireflies: int = 0  # 0 = use level's total_fireflies from GameManager
@export var auto_advance: bool = true  # Automatically go to next level

# Signals
signal goal_reached(player: Node)
signal goal_denied(player: Node, reason: String)

# State
var is_active: bool = true
var time_start = 0
var time_end = 0
var final_time = 0
# Node references
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	time_start = Time.get_unix_time_from_system()
	add_to_group("Goal")
	
	# Connect signals
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Get required fireflies from GameManager if not set
	if required_fireflies == 0 and GameManager:
		required_fireflies = GameManager.total_fireflies
	

func _on_area_entered(area: Area2D) -> void:
	"""Detect player via Area2D."""
	var parent = area.get_parent()
	if parent and parent.is_in_group("Player"):
		_check_completion(parent)

func _on_body_entered(body: Node) -> void:
	"""Detect player via CharacterBody2D."""
	if body.is_in_group("Player"):
		_check_completion(body)

func _check_completion(player: Node) -> void:
	"""Check if level can be completed."""
	if not is_active:
		return
	
	# Check if requirements are met
	var can_complete = true
	var deny_reason = ""
	
	# Check firefly requirement
	if require_all_fireflies and GameManager:
		var collected = GameManager.fireflies_collected
		var required = required_fireflies if required_fireflies > 0 else GameManager.total_fireflies
		
		if collected < required:
			can_complete = false
			deny_reason = "Need %d more fireflies" % (required - collected)
		
	if can_complete:
		_complete_level(player)
	else:
		_deny_completion(player, deny_reason)

func _complete_level(player: Node) -> void:
	"""Level completed successfully."""
	is_active = false  # Prevent multiple triggers
	time_end = Time.get_unix_time_from_system()
	var elapsed_time = int(time_end - time_start)
	final_time = format_elapsed_time(elapsed_time)
	print(final_time)
	GameManager.play_time = final_time
	
	# TODO: Play victory sound
	
	# Call GameManager to handle level completion
	if GameManager:
		GameManager.try_complete_level()
	
	# TODO: Disable player input during transition
	if player.has_method("set_can_move"):
		player.set_can_move(false)

func _deny_completion(player: Node, reason: String) -> void:
	"""Player tried to complete but doesn't meet requirements."""
	goal_denied.emit(player, reason)
	
	# TODO: Play denial sound
	# TODO: Show message to player
	# TODO: Flash goal sprite red
	
	print("Goal denied: " + reason)

func activate() -> void:
	"""Enable goal (for puzzles where goal unlocks)."""
	is_active = true
	# TODO: Visual change (color, glow)
	if sprite:
		sprite.modulate = Color.WHITE

func deactivate() -> void:
	"""Disable goal temporarily."""
	is_active = false
	# TODO: Visual change (grey out)
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)

func format_elapsed_time(seconds: int) -> String:
	var hours = seconds / 3600
	var minutes = (seconds % 3600) / 60
	var secs = seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]
