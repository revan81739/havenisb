extends Area2D

@export var speed := 900.0

var direction := Vector2.RIGHT


func _ready() -> void:
	body_entered.connect(hit)


func _physics_process(delta: float) -> void:
	# Added missing '*' operators for multiplication
	global_position += direction * speed  *delta


func hit(body: Node2D) -> void:
	print("Hit:", body.name)

	if body.is_in_group("enemy"):
		print("Enemy killed")

		if body.has_method("die"):
			body.die()

	# Destroys the bullet upon hitting anything. 
	# (Make sure your collision layers/masks are set up so bullets only hit enemies/walls!)
	queue_free()
