extends Node2D

@export var asteroid_scene: PackedScene
@export var spawn_interval := 5.0

var timer := 0.0


func _process(delta):

	timer += delta

	if timer >= spawn_interval:
		timer = 0.0
		spawn_asteroid()


func spawn_asteroid():

	var asteroid = asteroid_scene.instantiate()

	asteroid.global_position = global_position

	get_parent().add_child(asteroid)
