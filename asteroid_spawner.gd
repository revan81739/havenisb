extends Node2D

@export var asteroid_scene: PackedScene

@export var spawn_x := 1300
@export var min_y := 50
@export var max_y := 670

@export var spawn_interval := 5.0

var timer := 0.0


func _process(delta):

	timer += delta

	if timer >= spawn_interval:
		timer = 0.0
		spawn_asteroid()


func spawn_asteroid():

	var asteroid = asteroid_scene.instantiate()

	asteroid.position = Vector2(
		spawn_x,
		randf_range(min_y, max_y)
	)

	get_parent().add_child(asteroid)
