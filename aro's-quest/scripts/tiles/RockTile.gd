extends StaticBody2D
class_name RockTile

# Rock tile is a solid obstacle that damages player on collision
# Can be placed as instance or in TileMap depending on needs

@export var damage_on_collision: bool = true
@export var damage_amount: int = 1

func _ready() -> void:
	add_to_group("Obstacle")
	
	# Connect collision signal if using Area2D trigger approach
	# If using StaticBody2D, player handles collision in their script

# Alternative: Use Area2D for trigger-based collision
func _on_area_entered(area: Area2D) -> void:
	"""Called if this rock uses Area2D trigger instead of solid body."""
	if area.is_in_group("Player") and damage_on_collision:
		_damage_player(area)

func _damage_player(player_area: Area2D) -> void:
	"""Deal damage to player."""
	# Get player node (Area2D parent should be Player CharacterBody2D)
	var player = player_area.get_parent()
	if player and player.has_method("take_damage"):
		player.take_damage(damage_amount)
	
	# Alternative: Call GameManager directly
	# GameManager.on_player_hit_rock()
	
	# TODO: Play rock collision sound
	# TODO: Add particle effect or screen shake
