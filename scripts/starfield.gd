extends Node2D
## Scrolling space background.
##
## The Sprite2D children of this node are the background art. They live inside
## a CanvasLayer, which is fixed to the screen, so on their own they never move
## and the world looks frozen even while the camera follows the player.
## This script slides them against the camera (parallax) and wraps them around,
## so the background repeats forever.
##
## Add or remove Sprite2D copies as you like: they are laid out edge to edge,
## in child order, starting from where the first one sits in the editor.

## 0 = background never moves, 1 = background moves exactly with the world.
## Lower = looks further away. Raise it if the ship feels like it isn't moving.
@export_range(0.0, 1.0) var parallax := 0.6

var _sprites: Array[Sprite2D] = []
var _base_x: Array[float] = []
var _tile_width := 0.0
var _cam_origin := NAN


func _ready() -> void:
	for child in get_children():
		var sprite := child as Sprite2D
		if sprite != null and sprite.texture != null:
			_sprites.append(sprite)
	if _sprites.is_empty():
		set_process(false)
		return

	# One tile = the on-screen width of one sprite.
	var first := _sprites[0]
	_tile_width = first.texture.get_size().x * absf(first.scale.x)
	for i in _sprites.size():
		_base_x.append(first.position.x + i * _tile_width)

	var screen_w := get_viewport_rect().size.x
	var needed := ceili((screen_w + 1.5 * _tile_width) / _tile_width)
	if _sprites.size() < needed:
		push_warning("Starfield: add more background Sprite2D copies (%d needed, %d found) or gaps will show." % [needed, _sprites.size()])


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var cam_x := cam.global_position.x
	if is_nan(_cam_origin):
		# What you see at the start is exactly the layout you made in the editor.
		_cam_origin = cam_x

	var shift := (cam_x - _cam_origin) * parallax
	var total := _tile_width * _sprites.size()
	# Tiles wrap around inside [lo, lo + total). lo is far enough left of the
	# screen that a tile is fully off-screen when it jumps, so nothing pops.
	var lo := -_tile_width
	for i in _sprites.size():
		_sprites[i].position.x = lo + fposmod(_base_x[i] - shift - lo, total)
