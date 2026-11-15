class_name PlayerBullet
extends Area2D
## Animated bullet fired by the player. Only detects enemies (layer mask),
## so asteroids, pads and enemy bullets are completely ignored.

@export var speed := 800.0
@export var lifetime := 2.0

var direction := Vector2.RIGHT

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player_bullets")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(Layers.PLAYER_BULLET, true)
	set_collision_mask_value(Layers.ENEMY, true)

	area_entered.connect(_on_area_entered)
	sprite.play() # plays the sprite's current animation ("default")


## Call AFTER the bullet has been added to the scene tree.
func launch(from: Vector2, dir: Vector2) -> void:
	global_position = from
	direction = dir.normalized()
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var enemy := area as FlyingEnemy
	if enemy != null and enemy.die():
		queue_free()
