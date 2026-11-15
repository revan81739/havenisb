extends Node2D
## Level controller: camera follow, dialogue, spawning, oxygen timer, respawn.
##
## Level layout is done in the 2D editor:
##  - Ship          -> drag it right/left to make the level longer/shorter.
##  - OxygenTrigger -> drag it to where the oxygen dialogue should start.
##  - BouncePad     -> drag scenes/bounce_pad.tscn into the level wherever you want one.


## Hazards that are spawned at runtime and wiped on respawn.
## (Hand-placed BouncePads are NOT in here, so they survive a respawn.)
const CLEAR_GROUPS := ["enemies", "asteroids", "enemy_bullets", "player_bullets"]

const DIALOGUE_RESOURCE = preload("res://dialogue/level.dialogue")

@export_group("Dialogue")
@export var start_cue := "level_start"
@export var oxygen_cue := "oxygen_low"
@export var end_cue := "level_end"

@export_group("Camera")
## How far ahead of the player the camera centre sits. Bigger = player sits
## further to the left of the screen (you see more of what is coming).
@export var camera_lead := 400.0
## How tightly the camera follows the player. Higher = snappier, lower = floatier.
@export var camera_smoothing := 6.0

@export_group("Level")
## No hazards spawn within this distance of the Ship.
@export var spawn_cutoff := 400.0
@export var spawn_range_y := 300.0
@export var respawn_delay := 0.8

@export_group("Oxygen")
## SECONDS the oxygen bar takes to go from full to empty once the oxygen
## dialogue has finished. When it hits zero the player dies and respawns.
## See the "Oxygen:" line printed in the Output panel for a starting value.
@export var oxygen_duration := 55.0

@export_group("Spawning")
@export var enemy_interval := 5.0
@export var max_enemies := 4
@export var asteroid_interval := 2.0
@export var asteroid_speed_min := 220.0
@export var asteroid_speed_max := 380.0

var _enemy_scene: PackedScene = load("res://scenes/flying_enemy.tscn")
var _asteroid_scene: PackedScene = load("res://scenes/asteroid.tscn")


var _camera_start_x := 0.0
var _finished := false
var _frozen := false

## Bumped on every respawn so a dialogue that was already running can tell
## it belongs to an old attempt and must not start the oxygen timer.
var _attempt := 0
var _oxygen_triggered := false
var _oxygen_active := false
var _oxygen_left := 0.0

var _enemy_timer: Timer
var _asteroid_timer: Timer

@onready var camera: Camera2D = $Camera2D
@onready var player: Player = $Player
@onready var ship: Ship = $Ship
@onready var hud: GameHUD = $Hud
@onready var player_start: Marker2D = $PlayerStart
@onready var oxygen_trigger: Marker2D = $OxygenTrigger
@onready var enemy_spawn: Marker2D = $Camera2D/EnemySpawn
@onready var asteroid_spawn: Marker2D = $Camera2D/AsteroidSpawn


func _ready() -> void:
	_camera_start_x = camera.global_position.x

	player.global_position = player_start.global_position

	player.health_changed.connect(hud.set_health)
	player.dash_charge_changed.connect(hud.set_dash_charge)
	player.died.connect(_on_player_died)
	ship.reached.connect(_on_ship_reached)

	_enemy_timer = _make_timer(enemy_interval, _spawn_enemy)
	_asteroid_timer = _make_timer(asteroid_interval, _spawn_asteroid)

	hud.set_health(player.health, player.max_health)
	hud.set_dash_charge(1.0)

	# Deferred so the scene is completely set up before the dialogue is added.
	_run_intro.call_deferred()


func _physics_process(delta: float) -> void:
	if _frozen:
		return
	_update_camera(delta)
	_check_oxygen_trigger()
	_update_oxygen(delta)


# -------------------------------------------------------------------- camera

## The camera follows the player to the right and never scrolls back, so
## knockback can still push the player towards the left edge of the screen.
func _update_camera(delta: float) -> void:
	var target_x := player.global_position.x + camera_lead
	var weight := 1.0 - exp(-camera_smoothing * delta)
	var followed := lerpf(camera.global_position.x, target_x, weight)
	camera.global_position.x = maxf(camera.global_position.x, followed)


# ------------------------------------------------------------------ dialogue

func _run_intro() -> void:
	await _show_dialogue(start_cue)
	_start_spawning()


func _show_dialogue(cue: String) -> void:
	_set_world_frozen(true)
	var balloon = DialogueManager.show_dialogue_balloon(DIALOGUE_RESOURCE, cue)
	if balloon != null:
		await balloon.tree_exited
	_set_world_frozen(false)


## Same idea as your old level: disable processing instead of pausing the tree.
func _set_world_frozen(frozen: bool) -> void:
	_frozen = frozen
	var mode := Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT
	player.process_mode = mode
	for group in CLEAR_GROUPS:
		for node in get_tree().get_nodes_in_group(group):
			node.process_mode = mode


# -------------------------------------------------------------------- oxygen

func _check_oxygen_trigger() -> void:
	if _oxygen_triggered or _finished or player.dead:
		return
	if player.global_position.x >= oxygen_trigger.global_position.x:
		_oxygen_triggered = true
		# Deferred: keep the freeze out of the physics step.
		_run_oxygen_sequence.call_deferred()


func _run_oxygen_sequence() -> void:
	var attempt := _attempt
	await _show_dialogue(oxygen_cue)
	# The level was reset or finished while the dialogue was open.
	if attempt != _attempt or _finished:
		return

	_oxygen_left = maxf(oxygen_duration, 0.01)
	_oxygen_active = true
	hud.set_oxygen(1.0)
	hud.show_oxygen()

	# Tuning helper: shows how long the rest of the level takes at cruise speed.
	var distance := ship.global_position.x - oxygen_trigger.global_position.x
	var minimum := distance / maxf(player.cruise_speed, 1.0)
	print("Oxygen: %.1fs available. Rest of level = %.0f px = %.1fs at cruise speed (%.0f px/s)."
			% [oxygen_duration, distance, minimum, player.cruise_speed])


func _update_oxygen(delta: float) -> void:
	if not _oxygen_active or player.dead:
		return
	_oxygen_left = maxf(_oxygen_left - delta, 0.0)
	hud.set_oxygen(_oxygen_left / maxf(oxygen_duration, 0.01))
	if _oxygen_left <= 0.0:
		_oxygen_active = false
		player.kill()


# --------------------------------------------------------------- level flow

func _on_ship_reached() -> void:
	if _finished:
		return
	_finished = true
	_oxygen_active = false
	hud.hide_oxygen()
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

	# Back to the start: the oxygen section re-arms and plays again.
	_attempt += 1
	_oxygen_triggered = false
	_oxygen_active = false
	hud.hide_oxygen()

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


func _stop_spawning() -> void:
	_enemy_timer.stop()
	_asteroid_timer.stop()


func _spawn_position(marker: Marker2D) -> Vector2:
	return marker.global_position + Vector2(0.0, randf_range(-spawn_range_y, spawn_range_y))


func _can_spawn(pos: Vector2) -> bool:
	return not _finished and not player.dead and pos.x < ship.global_position.x - spawn_cutoff


func _spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	var pos := _spawn_position(enemy_spawn)
	if not _can_spawn(pos):
		return
	var enemy := _enemy_scene.instantiate() as FlyingEnemy
	# Enemies drift forward at the player's cruise speed so they keep pace.
	enemy.scroll_speed = player.cruise_speed
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
