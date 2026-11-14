extends Node2D

@export var enemy_scene: PackedScene

@export var spawn_x := 1300
@export var min_y := 50
@export var max_y := 650

@export var spawn_interval := 8.5

func _ready():
	randomize()

	var timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.timeout.connect(spawn_enemy)
	add_child(timer)


func spawn_enemy():
	var enemy = enemy_scene.instantiate()

	enemy.global_position = Vector2(
		spawn_x,
		randi_range(min_y, max_y)
	)

	get_tree().current_scene.add_child(enemy)
