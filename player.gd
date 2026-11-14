extends CharacterBody2D

@export var drift_speed := 120.0      
@export var thrust := 250.0               
@export var braking_force := 500.0         

@export var dash_speed := 1000.0
@export var dash_duration := 0.35
@export var dash_cooldown := 3.0

@export var max_health := 5

@onready var sprite = $Sprite2D

var current_health

var can_dash := true
var is_dashing := false
var is_invincible := false

var dash_timer := 0.0
var cooldown_timer := 0.0


func _ready():
	current_health = max_health


func _physics_process(delta):

	# Dash cooldown
	if !can_dash:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			can_dash = true

	# Dash
	if is_dashing:
		velocity = Vector2(dash_speed, 0)

		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	else:

		# Constant drift to the right
		velocity.x = drift_speed

		# Vertical movement
		if Input.is_action_pressed("ui_up"):
			velocity.y = -thrust
		elif Input.is_action_pressed("ui_down"):
			velocity.y = thrust
		else:
			velocity.y = move_toward(velocity.y, 0, thrust * 2 * delta)

		# Brake with A
		if Input.is_action_pressed("ui_left"):
			velocity.x -= braking_force

		# Dash with D action
		if Input.is_action_just_pressed("Dash") and can_dash:
			start_dash()

	move_and_slide()


func start_dash():
	can_dash = false
	is_dashing = true
	is_invincible = true

	dash_timer = dash_duration
	cooldown_timer = dash_cooldown

	flash()

	await get_tree().create_timer(dash_duration).timeout
	is_invincible = false


func take_damage(amount):
	if is_invincible:
		return

	current_health -= amount
	print("Health:", current_health)

	if current_health <= 0:
		die()


func die():
	print("You died...")
	queue_free()


func flash():
	sprite.modulate = Color(10, 10, 10, 1)
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color.WHITE
