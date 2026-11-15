class_name EnemyBullet
extends Area2D
## Animated bullet fired by flying enemies. Deals 1 damage and disappears
## when it actually hurts the player. While the player is invincible
## (dashing) it simply passes through.

@export var speed := 320.0
@export var lifetime := 6.0
@export var damage := 1

var direction := Vector2.LEFT

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemy_bullets")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(Layers.ENEMY_BULLET, true)
	set_collision_mask_value(Layers.PLAYER, true)

	area_entered.connect(_on_area_entered)
	sprite.play()


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
	var player := area as Player
	if player != null and player.take_damage(damage):
		queue_free()
