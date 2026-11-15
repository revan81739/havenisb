extends Sprite2D
## Crosshair that replaces the mouse cursor. Lives inside the HUD CanvasLayer
## so it is drawn in screen space (unaffected by the moving camera).


func _ready() -> void:
	# Keep following the mouse while a dialogue has the game paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN


func _process(_delta: float) -> void:
	global_position = get_viewport().get_mouse_position()
