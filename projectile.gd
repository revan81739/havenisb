extends Area2D

@export var speed := 900.0

var direction := Vector2.RIGHT


func _physics_process(delta):
	position += direction * speed * delta

	
	if position.x > 2000 or position.x < -200:
		queue_free()


func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("die"):
			body.die()

		queue_free()
