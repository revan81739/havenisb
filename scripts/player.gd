class_name Player
extends Area2D
## The astronaut.
## - Floats right at a constant speed and slowly, randomly spins (zero-g).
## - W / S = move up / down, A = slow down, D = dash (invincible + white flash).
## - Left mouse button = shoot towards the crosshair.
## Hazards (bullets, asteroids, pads, ship) detect the player themselves and
## call take_damage() / apply_knockback() / bounce() on this node.

signal health_changed(current: int, maximum: int)
signal dash_charge_changed(fraction: float) # 0.0 = just used, 1.0 = ready
signal died

@export_group("Movement")
## Speed (px/s) the player drifts right with no input. The camera follows the
## player, and Main uses this value for enemy drift and the oxygen estimate.
@export var cruise_speed := 300.0
@export var vertical_speed := 320.0
@export var vertical_accel := 900.0
@export var forward_accel := 900.0
## A key: forward speed is multiplied by this while held.
@export_range(0.0, 1.0) var slow_factor := 0.4
## How close to the screen edge the player may get.
@export var edge_margin := 40.0

@export_group("Dash")
@export var dash_speed := 800.0
@export var dash_duration := 0.25
@export var dash_cooldown := 3.0

@export_group("Impulses")
## How quickly bounce / knockback impulses fade out (bigger = faster).
@export var impulse_damping := 3.0
@export var bounce_speed := 650.0
@export var knockback_speed := 800.0

@export_group("Zero-G spin")
## Maximum rotation speed in radians per second.
@export var max_spin := 0.9
## How smoothly the spin changes (bigger = snappier).
@export var spin_smoothing := 1.5

@export_group("Combat")
@export var max_health := 7
@export var shoot_cooldown := 0.25
@export var respawn_invulnerability := 1.5

var health := 0
var dead := false

var _forward_speed := 0.0
var _vertical_speed := 0.0
var _impulse := Vector2.ZERO

var _dash_time_left := 0.0
var _dash_cooldown_left := 0.0
var _shoot_cooldown_left := 0.0
var _spawn_invuln_left := 0.0

var _spin := 0.0
var _target_spin := 0.0
var _spin_timer := 0.0

var _flash_tween: Tween

# load() at runtime (instead of preload) avoids cyclic-reference problems
# and means the scripts parse even before every scene exists.
var _bullet_scene: PackedScene = load("res://scenes/player_bullet.tscn")
var _flash_shader: Shader = load("res://shaders/flash.gdshader")

@onready var sprite: Node2D = $Sprite2D
@onready var muzzle: Marker2D = $Sprite2D/Muzzle


func _ready() -> void:
	add_to_group("player")

	collision_layer = 0
	collision_mask = 0
	set_collision_layer_value(Layers.PLAYER, true)

	
	var mat := ShaderMaterial.new()
	mat.shader = _flash_shader
	sprite.material = mat

	sprite.rotation = randf() * TAU
	health = max_health
	_forward_speed = cruise_speed


func _physics_process(delta: float) -> void:
	if dead:
		return
	_tick_timers(delta)
	_update_movement(delta)
	_update_spin(delta)
	_update_blink()


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	
	if event.is_action_pressed("shoot"):
		_shoot()




func is_invincible() -> bool:
	return _dash_time_left > 0.0 or _spawn_invuln_left > 0.0



func take_damage(amount: int) -> bool:
	if dead or is_invincible():
		return false
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()
	else:
		_flash(Color(1.0, 0.25, 0.25), 0.05, 0.25)
	return true


## Launches the player in `direction` (used by asteroids: Vector2.LEFT).
func apply_knockback(direction: Vector2) -> void:
	if dead:
		return
	_vertical_speed = 0.0
	_impulse = direction.normalized() * knockback_speed


## Launches the player in `direction` (used by bounce pads).
func bounce(direction: Vector2) -> void:
	if dead:
		return
	_vertical_speed = 0.0
	_impulse = direction.normalized() * bounce_speed


## Kills the player outright, ignoring dash/respawn invincibility.
## Used by Main when the oxygen runs out.
func kill() -> void:
	if dead:
		return
	health = 0
	health_changed.emit(health, max_health)
	_die()


## Puts the player back at `at` with full health and a short grace period.
func respawn(at: Vector2) -> void:
	global_position = at
	dead = false
	visible = true
	set_deferred("monitorable", true)
	health = max_health
	_forward_speed = cruise_speed
	_vertical_speed = 0.0
	_impulse = Vector2.ZERO
	_dash_time_left = 0.0
	_dash_cooldown_left = 0.0
	_shoot_cooldown_left = 0.0
	_spawn_invuln_left = respawn_invulnerability
	_stop_flash()
	health_changed.emit(health, max_health)
	dash_charge_changed.emit(1.0)


# ------------------------------------------------------------------ internals

func _tick_timers(delta: float) -> void:
	_shoot_cooldown_left = maxf(_shoot_cooldown_left - delta, 0.0)
	_spawn_invuln_left = maxf(_spawn_invuln_left - delta, 0.0)
	_dash_time_left = maxf(_dash_time_left - delta, 0.0)

	if _dash_cooldown_left > 0.0:
		_dash_cooldown_left = maxf(_dash_cooldown_left - delta, 0.0)
		dash_charge_changed.emit(1.0 - _dash_cooldown_left / dash_cooldown)

	if Input.is_action_just_pressed("dash") and _dash_cooldown_left <= 0.0:
		_start_dash()


func _update_movement(delta: float) -> void:
	# Forward: constant drift, slower while A is held, burst while dashing.
	var target_forward := cruise_speed
	if Input.is_action_pressed("slow"):
		target_forward = cruise_speed * slow_factor

	if _dash_time_left > 0.0:
		_forward_speed = dash_speed
	else:
		_forward_speed = move_toward(_forward_speed, target_forward, forward_accel * delta)

	# Vertical: W up, S down, with a little floaty acceleration.
	var input_y := Input.get_axis("move_up", "move_down")
	_vertical_speed = move_toward(_vertical_speed, input_y * vertical_speed, vertical_accel * delta)

	# Bounce / knockback impulse fades out smoothly (frame-rate independent).
	_impulse = _impulse.lerp(Vector2.ZERO, 1.0 - exp(-impulse_damping * delta))

	var velocity := Vector2(_forward_speed, _vertical_speed) + _impulse
	global_position += velocity * delta
	_clamp_to_screen()


func _clamp_to_screen() -> void:
	var half := get_viewport_rect().size * 0.5
	var cam := get_viewport().get_camera_2d()
	var center := cam.global_position if cam != null else half
	var margin := Vector2(edge_margin, edge_margin)
	global_position = global_position.clamp(center - half + margin, center + half - margin)


func _update_spin(delta: float) -> void:
	_spin_timer -= delta
	if _spin_timer <= 0.0:
		_target_spin = randf_range(-max_spin, max_spin)
		_spin_timer = randf_range(1.5, 3.5)
	_spin = lerpf(_spin, _target_spin, 1.0 - exp(-spin_smoothing * delta))
	sprite.rotation = wrapf(sprite.rotation + _spin * delta, -PI, PI)


func _update_blink() -> void:
	# Only the respawn grace period blinks; the dash uses the white flash instead.
	if _spawn_invuln_left > 0.0:
		sprite.modulate.a = 0.35 if int(_spawn_invuln_left * 12.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0


func _start_dash() -> void:
	_dash_time_left = dash_duration
	_dash_cooldown_left = dash_cooldown
	dash_charge_changed.emit(0.0)
	_flash(Color.WHITE, 0.12, 0.25)


func _shoot() -> void:
	if _shoot_cooldown_left > 0.0:
		return
	_shoot_cooldown_left = shoot_cooldown

	var origin := muzzle.global_position
	var direction := (get_global_mouse_position() - origin).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	var bullet := _bullet_scene.instantiate() as PlayerBullet
	get_tree().current_scene.add_child(bullet)
	bullet.launch(origin, direction)


func _die() -> void:
	dead = true
	visible = false
	# Deferred: we may be inside a physics callback (area_entered).
	set_deferred("monitorable", false)
	_stop_flash()
	died.emit()


func _flash(color: Color, hold: float, fade: float) -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	(sprite.material as ShaderMaterial).set_shader_parameter("flash_color", color)
	_set_flash_amount(1.0)
	_flash_tween = create_tween()
	_flash_tween.tween_interval(hold)
	_flash_tween.tween_method(_set_flash_amount, 1.0, 0.0, fade)


func _stop_flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_set_flash_amount(0.0)


func _set_flash_amount(value: float) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("flash_amount", value)
