extends Node2D
@onready var sprite = $Area2D/AnimatedSprite2D
@onready var timer = $Area2D/Timer
signal collected
func _ready() -> void:
	sprite.play("idle")
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("collected")
		emit_signal("collected")
		$collected.play()
