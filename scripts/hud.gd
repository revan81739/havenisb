class_name GameHUD
extends CanvasLayer
## Top-right health bar (7 HP) with the dash-cooldown bar under it, and the
## oxygen bar (hidden until the oxygen section starts) under that.
## Main connects the Player's signals to set_health() / set_dash_charge().

@onready var health_bar := find_child("HealthBar", true, false) as ProgressBar
@onready var dash_bar := find_child("DashBar", true, false) as ProgressBar
@onready var oxygen_bar := find_child("OxygenBar", true, false) as ProgressBar


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

	# Hidden until the oxygen dialogue has finished.
	oxygen_bar.show_percentage = false
	oxygen_bar.min_value = 0.0
	oxygen_bar.max_value = 1.0
	oxygen_bar.step = 0.001
	oxygen_bar.value = 1.0
	oxygen_bar.visible = false


func set_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current


## fraction: 0.0 = dash just used, 1.0 = ready again.
func set_dash_charge(fraction: float) -> void:
	dash_bar.value = clampf(fraction, 0.0, 1.0)


func show_oxygen() -> void:
	oxygen_bar.visible = true


func hide_oxygen() -> void:
	oxygen_bar.visible = false


## fraction: 1.0 = full tank, 0.0 = empty (player dies).
func set_oxygen(fraction: float) -> void:
	oxygen_bar.value = clampf(fraction, 0.0, 1.0)
