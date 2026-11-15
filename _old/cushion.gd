extends Area2D

@export var bounce_strength := 700.0

func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("player"):

		# Random direction
		var direction = Vector2(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()

		# Prevent an extremely tiny vector
		if direction.length() < 0.1:
			direction = Vector2.RIGHT

		body.velocity = direction * bounce_strength
