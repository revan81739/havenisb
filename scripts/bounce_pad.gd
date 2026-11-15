class_name BouncePad
extends Area2D
## Cushioned pad. Sits still in the world; when the player touches it he is
## launched in a completely random direction. Does nothing else.

const DESPAWN_DISTANCE := 1800.0


func _ready() -> void:
	add_to_group("pads")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(Layers.PAD, true)
	set_collision_mask_value(Layers.PLAYER, true)

	area_entered.connect(_on_area_entered)


func _physics_process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam != null and global_position.distance_to(cam.global_position) > DESPAWN_DISTANCE:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var player := area as Player
	if player != null:
		player.bounce(Vector2.from_angle(randf() * TAU))
