class_name GameHUD
extends CanvasLayer
## Top-right health bar (7 HP) with the dash-cooldown bar under it.
## Main connects the Player's signals to set_health() / set_dash_charge().

@onready var health_bar := find_child("HealthBar", true, false) as ProgressBar
@onready var dash_bar := find_child("DashBar", true, false) as ProgressBar


func _ready() -> void:
	# HUD must never swallow mouse clicks (they are needed for shooting).
	for c in find_children("*", "Control", true, false):
		(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

	health_bar.show_percentage = false
	health_bar.min_value = 0.0
	health_bar.step = 1.0

	dash_bar.show_percentage = false
	dash_bar.min_value = 0.0
	dash_bar.max_value = 1.0
	dash_bar.step = 0.001
	dash_bar.value = 1.0


func set_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


## fraction: 0.0 = dash just used, 1.0 = ready again.
func set_dash_charge(fraction: float) -> void:
	dash_bar.value = clampf(fraction, 0.0, 1.0)
