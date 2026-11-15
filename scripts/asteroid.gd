class_name Asteroid
extends Area2D
## Asteroid: flies in a straight line (left) forever, never tracks the player
## and ignores the player's bullets. Hits the player ONCE for 3 damage, throws
## him straight backwards (left), then keeps flying.

## Anything further than this from the camera is deleted so they don't pile up.
const DESPAWN_DISTANCE := 1800.0

@export var speed := 280.0
@export var damage := 3
## Max visual spin in radians per second.
@export var max_spin := 1.2

var direction := Vector2.LEFT

var _has_hit := false
var _spin := 0.0


func _ready() -> void:
	add_to_group("asteroids")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(Layers.ASTEROID, true)
	set_collision_mask_value(Layers.PLAYER, true)

	area_entered.connect(_on_area_entered)

	rotation = randf() * TAU
	_spin = randf_range(-max_spin, max_spin)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	rotation += _spin * delta

	var cam := get_viewport().get_camera_2d()
	if cam != null and global_position.distance_to(cam.global_position) > DESPAWN_DISTANCE:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _has_hit:
		return
	var player := area as Player
	if player == null:
		return
	# take_damage() returns false while the player is invincible (dashing),
	# in which case the asteroid just passes through without knocking back.
	if player.take_damage(damage):
		_has_hit = true # a single asteroid can only hurt once
		player.apply_knockback(Vector2.LEFT) # "straight backwards"
