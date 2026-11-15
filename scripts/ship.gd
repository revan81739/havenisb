class_name Ship
extends Area2D
## The goal. Main places it at x = level_length. Its collision shape is a tall
## rectangle so the player can't fly over or under it.

signal reached

var _triggered := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(Layers.GOAL, true)
	set_collision_mask_value(Layers.PLAYER, true)
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if _triggered:
		return
	if area is Player:
		_triggered = true
		reached.emit()
