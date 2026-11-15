class_name BouncePad
extends Area2D
## Cushioned pad. Place it by hand in the level (drag scenes/bounce_pad.tscn
## into the 2D editor); it stays exactly where you put it. When the player
## touches it he is launched in a completely random direction.


func _ready() -> void:
	add_to_group("pads")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(Layers.PAD, true)
	set_collision_mask_value(Layers.PLAYER, true)

	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	var player := area as Player
	if player != null:
		player.bounce(Vector2.from_angle(randf() * TAU))
