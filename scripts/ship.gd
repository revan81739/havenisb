class_name Ship
extends Area2D
## The goal. Drag it along the x axis in the 2D editor to set the level length.
## Its collision shape is a tall rectangle so the player can't fly over or under it.

signal reached

## The camera follows the player anywhere, so the trigger shape is stretched
## to at least this height at runtime. Without it the player could fly over
## or under the ship without touching it.
@export var trigger_height := 8000.0

var _triggered := false


func _ready() -> void:
	_stretch_trigger()
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(Layers.GOAL, true)
	set_collision_mask_value(Layers.PLAYER, true)
	area_entered.connect(_on_area_entered)


func _stretch_trigger() -> void:
	for child in get_children():
		var collision := child as CollisionShape2D
		if collision != null and collision.shape is RectangleShape2D:
			var rect := (collision.shape as RectangleShape2D).duplicate() as RectangleShape2D
			rect.size.y = maxf(rect.size.y, trigger_height)
			collision.shape = rect


func _on_area_entered(area: Area2D) -> void:
	if _triggered:
		return
	if area is Player:
		_triggered = true
		reached.emit()
