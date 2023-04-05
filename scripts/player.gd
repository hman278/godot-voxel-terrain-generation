extends CharacterBody3D

@onready var camera = $camera
@onready var hand = $camera/hand
@onready var water_env = preload("res://underwater_environment.tres")
@onready var water_plane = $camera/water_plane

# camera properties
var mouse_sens = 0.15

# movement properties
const JUMP_HEIGHT = 9.0
const GRAVITY = -9.8
const GRAVITY_MULTIPLIER = 4.0
var speed = 0.0
const WALK_SPEED = 4.0
const RUN_SPEED = 8.0
const SWIM_SPEED = 2.0
var bob_speed = 0.0

const ACCEL_SPEED: int = 1
var accel = 0

@onready var initial_hand_pos = hand.transform.origin
@onready var initial_head_pos = camera.transform.origin

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)

func _physics_process(delta):
	var is_in_water = global_transform.origin.y < -1
	var is_under_water = global_transform.origin.y < -2
	
	# quit the game if esc pressed
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	
	if Input.is_action_just_pressed("switch_window_mode"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	speed = WALK_SPEED
	bob_speed = 0.0065 * WALK_SPEED * 0.2
	if Input.is_action_pressed("run") and not is_in_water:
		speed = RUN_SPEED
		bob_speed = 0.0065 * RUN_SPEED * 0.2
	
	if is_in_water: 
		speed = SWIM_SPEED
		if is_under_water:
			camera.environment = water_env
			camera.attributes.dof_blur_far_enabled = true
			water_plane.visible = true
		else:
			camera.environment = null
			camera.attributes.dof_blur_far_enabled = false
			water_plane.visible = false
	
	velocity.y += GRAVITY * delta * GRAVITY_MULTIPLIER
	
	# set the acceleration value
	if get_input_direction() != Vector3.ZERO:
		accel = lerpf(accel, ACCEL_SPEED, delta * 2)
		
		if velocity.length() > 0: 
			hand_bob()
			head_bob()
	else:
		accel = lerpf(accel, 0, delta * 100)
		reset_moving_parts(delta)
	
	var desired_velocity = get_input_direction() * speed * accel
	
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	
	if is_on_floor():
		velocity.y = 0
	
	if Input.is_action_just_pressed('jump') and is_on_floor():
		velocity.y = JUMP_HEIGHT
	
	move_and_slide()

func _input(event):
	if (event is InputEventMouseMotion):
		camera.rotation_degrees.x -= event.relative.y * mouse_sens
		rotation_degrees.y -= event.relative.x * mouse_sens
		
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -90, 90)

func get_input_direction():
	var direction = Vector3.ZERO
	if Input.is_action_pressed('move_forward'):
		direction -= global_transform.basis.z
	if Input.is_action_pressed('move_backward'):
		direction += global_transform.basis.z
	if Input.is_action_pressed('move_left'):
		direction -= global_transform.basis.x
	if Input.is_action_pressed('move_right'):
		direction += global_transform.basis.x
	
	return direction.normalized()

func hand_bob():
	var x_translation = sin(Time.get_ticks_msec() * bob_speed) * 0.1
	var y_translation = sin(Time.get_ticks_msec() * bob_speed * -2) * 0.01
	
	hand.translate_object_local(Vector3.RIGHT * x_translation)
	hand.global_translate(Vector3.UP * y_translation)

func head_bob():
	var y_translation = sin(Time.get_ticks_msec() * bob_speed * 2) * 0.02
	camera.translate_object_local(Vector3.UP * y_translation)

var t = 0.0
func reset_moving_parts(delta: float):
	t += delta
	hand.transform.origin.x = lerp(hand.transform.origin.x, initial_hand_pos.x, t)
	hand.transform.origin.y = lerp(hand.transform.origin.y, initial_hand_pos.y, t)
	
	camera.transform.origin.y = lerp(camera.transform.origin.y, initial_head_pos.y, t)
	
	if t > 1: t = 0
