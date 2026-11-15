extends Node2D
## OPTIONAL scrolling star background (no art needed). Put it inside a
## CanvasLayer with Layer = -10 so it is drawn behind everything and stays
## fixed to the screen while the stars slide past at different speeds.

@export var star_count := 140
@export var parallax := 0.35

var _stars: Array[Vector3] = [] # x, y, depth (0.15 far .. 1.0 near)


func _ready() -> void:
	var size := get_viewport_rect().size
	for i in star_count:
		_stars.append(Vector3(randf() * size.x, randf() * size.y, randf_range(0.15, 1.0)))


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	var cam := get_viewport().get_camera_2d()
	var cam_x := cam.global_position.x if cam != null else 0.0
	for s in _stars:
		var x := fposmod(s.x - cam_x * s.z * parallax, size.x)
		draw_circle(Vector2(x, s.y), 0.7 + s.z * 1.3, Color(1.0, 1.0, 1.0, 0.25 + 0.75 * s.z))
