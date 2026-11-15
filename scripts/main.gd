extends Node2D
## Level controller.
## - Scrolls the camera right at `scroll_speed` (the player floats at the same speed).
## - Spawns asteroids / flying enemies / bounce pads at Marker2D spawn points
##   that are children of the camera, just off the right edge of the screen.
## - Shows the start / end dialogue (the game is paused while it is open).
## - Handles player death (respawn at the start) and reaching the ship.

const CLEAR_GROUPS := ["enemies", "asteroids", "pads", "enemy_bullets", "player_bullets"]

const DIALOGUE_RESOURCE = preload("res://dialogue/level.dialogue")

@export_group("Dialogue")
@export var start_cue := "level_start"
@export var end_cue := "level_end"

@export_group("Level")
@export var scroll_speed := 180.0
## World x of the ship. Level time is roughly (level_length - 240) / scroll_speed seconds.
@export var level_length := 12000.0
## Nothing spawns closer than this to the ship.
@export var spawn_cutoff := 400.0
## Spawn height varies by +/- this much around the spawn marker's y.
@export var spawn_range_y := 300.0
@export var respawn_delay := 0.8

@export_group("Spawning")
@export var enemy_interval := 5.0
@export var max_enemies := 4
@export var asteroid_interval := 2.0
@export var asteroid_speed_min := 220.0
@export var asteroid_speed_max := 380.0
@export var pad_interval := 6.0

var _enemy_scene: PackedScene = load("res://scenes/flying_enemy.tscn")
var _asteroid_scene: PackedScene = load("res://scenes/asteroid.tscn")
var _pad_scene: PackedScene = load("res://scenes/bounce_pad.tscn")


var _camera_start_x := 0.0
var _finished := false
var _frozen := false

var _enemy_timer: Timer
var _asteroid_timer: Timer
var _pad_timer: Timer

@onready var camera: Camera2D = $Camera2D
@onready var player: Player = $Player
@onready var ship: Ship = $Ship
@onready var hud: GameHUD = $HUD
@onready var player_start: Marker2D = $PlayerStart
@onready var enemy_spawn: Marker2D = $Camera2D/EnemySpawn
@onready var asteroid_spawn: Marker2D = $Camera2D/AsteroidSpawn
@onready var pad_spawn: Marker2D = $Camera2D/PadSpawn


func _ready() -> void:
	_camera_start_x = camera.global_position.x

	# One source of truth for the speed: the player cruises at the scroll speed.
	player.cruise_speed = scroll_speed
	player.global_position = player_start.global_position
	ship.global_position = Vector2(level_length, camera.global_position.y)

	player.health_changed.connect(hud.set_health)
	player.dash_charge_changed.connect(hud.set_dash_charge)
	player.died.connect(_on_player_died)
	ship.reached.connect(_on_ship_reached)

	_enemy_timer = _make_timer(enemy_interval, _spawn_enemy)
	_asteroid_timer = _make_timer(asteroid_interval, _spawn_asteroid)
	_pad_timer = _make_timer(pad_interval, _spawn_pad)

	hud.set_health(player.health, player.max_health)
	hud.set_dash_charge(1.0)

	# Deferred so the scene is completely set up before the dialogue is added.
	_run_intro.call_deferred()


func _physics_process(delta: float) -> void:
	if _frozen:
		return
	camera.global_position.x += scroll_speed * delta


# ------------------------------------------------------------------ dialogue

func _run_intro() -> void:
	await _show_dialogue(start_cue)
	_start_spawning()





# --------------------------------------------------------------- level flow

func _on_ship_reached() -> void:
	if _finished:
		return
	_finished = true
	# Deferred: this signal arrives from inside a physics callback.
	_finish_level.call_deferred()


func _finish_level() -> void:
	_stop_spawning()
	await _show_dialogue(end_cue)
	# Replace with get_tree().change_scene_to_file("res://scenes/menu.tscn")
	# if you add a menu / credits screen later.
	get_tree().reload_current_scene()


func _on_player_died() -> void:
	await get_tree().create_timer(respawn_delay).timeout
	if _finished:
		return
	_reset_level()


func _reset_level() -> void:
	for group in CLEAR_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			node.queue_free()

	camera.global_position.x = _camera_start_x # camera first: the player clamps to it
	player.respawn(player_start.global_position)

	# Restart the intervals so the first hazards don't appear instantly.
	_start_spawning()


# ------------------------------------------------------------------ spawning

func _make_timer(interval: float, callback: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = interval
	timer.one_shot = false
	timer.autostart = false
	timer.timeout.connect(callback)
	add_child(timer)
	return timer


func _start_spawning() -> void:
	_enemy_timer.start()
	_asteroid_timer.start()
	_pad_timer.start()


func _stop_spawning() -> void:
	_enemy_timer.stop()
	_asteroid_timer.stop()
	_pad_timer.stop()


func _spawn_position(marker: Marker2D) -> Vector2:
	return marker.global_position + Vector2(0.0, randf_range(-spawn_range_y, spawn_range_y))


func _can_spawn(pos: Vector2) -> bool:
	return not _finished and not player.dead and pos.x < level_length - spawn_cutoff


func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	var pos := _spawn_position(enemy_spawn)
	if not _can_spawn(pos):
		return
	var enemy := _enemy_scene.instantiate() as FlyingEnemy
	enemy.scroll_speed = scroll_speed
	add_child(enemy)
	enemy.global_position = pos


func _spawn_asteroid() -> void:
	var pos := _spawn_position(asteroid_spawn)
	if not _can_spawn(pos):
		return
	var asteroid := _asteroid_scene.instantiate() as Asteroid
	asteroid.speed = randf_range(asteroid_speed_min, asteroid_speed_max)
	asteroid.scale = Vector2.ONE * randf_range(0.8, 1.5)
	add_child(asteroid)
	asteroid.global_position = pos


func _spawn_pad() -> void:
	var pos := _spawn_position(pad_spawn)
	if not _can_spawn(pos):
		return
	var pad := _pad_scene.instantiate() as BouncePad
	add_child(pad)
	pad.global_position = pos
