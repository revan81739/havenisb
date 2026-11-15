class_name FlyingEnemy
extends Area2D
## Flying alien. Drifts smoothly towards the player, stops chasing once it is
## `stop_distance` away, and fires a bullet at the player every `fire_interval`
## seconds (only while on screen). One hit kills it.
##
## The enemy also drifts forward at the player's cruise speed (scroll_speed,
## set by Main), otherwise the constantly moving player would simply leave it behind.

@export var chase_speed := 90.0
@export var acceleration := 120.0
@export var stop_distance := 380.0
@export var fire_interval := 1.8

## Set by Main right after instancing.
var scroll_speed := 0.0

var _chase_velocity := Vector2.ZERO
var _fire_cooldown := 0.0
var _dead := false

var _bullet_scene: PackedScene = load("res://scenes/enemy_bullet.tscn")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("enemies")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(Layers.ENEMY, true)

	_fire_cooldown = fire_interval # no instant shot on spawn
	sprite.play()


func _physics_process(delta: float) -> void:
	var scroll := Vector2(scroll_speed, 0.0)

	# Dying enemies just keep scrolling with the world while they fade out.
	if _dead:
		global_position += scroll * delta
		return

	var player := get_tree().get_first_node_in_group("player") as Player
	var target_velocity := Vector2.ZERO

	if player != null:
		var to_player := player.global_position - global_position
		if to_player.length() > stop_distance:
			target_velocity = to_player.normalized() * chase_speed
		# Assumes the art faces LEFT by default; remove this line (or invert
		# the comparison) if yours faces right.
		sprite.flip_h = to_player.x > 0.0

	# Smooth acceleration towards the target (and smooth stop when in range).
	_chase_velocity = _chase_velocity.move_toward(target_velocity, acceleration * delta)
	global_position += (_chase_velocity + scroll) * delta

	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	if _fire_cooldown <= 0.0 and player != null and not player.dead and _is_on_screen():
		_fire_cooldown = fire_interval
		_shoot_at(player)


## Returns true if this call killed the enemy (false if it was already dying).
func die() -> bool:
	if _dead:
		return false
	_dead = true
	# Deferred: we are usually inside a physics callback (bullet area_entered).
	set_deferred("monitorable", false)

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
	return true


func _shoot_at(target: Node2D) -> void:
	var direction := (target.global_position - global_position).normalized()
	if direction == Vector2.ZERO:
		return
	var bullet := _bullet_scene.instantiate() as EnemyBullet
	get_tree().current_scene.add_child(bullet)
	bullet.launch(global_position, direction)


func _is_on_screen() -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return true
	var half := get_viewport_rect().size * 0.5
	var offset := (global_position - cam.global_position).abs()
	return offset.x <= half.x and offset.y <= half.y
