extends Area2D

@export var speed := 350.0
@export var damage := 3

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta):
	position.x -= speed * delta

	# Delete once off-screen
	if position.x < -200:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage)

	queue_free()
