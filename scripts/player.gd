extends KinematicBody

onready var camera = $camera

# camera properties
var mouse_sens = 0.5
var mouse_sens_multiplier = 1
# multipliers for the final mouse sensitivity
var default_sens_multiplier = 0.5

# movement properties
var jump_height = 10
var gravity = -9.8
var gravity_multiplier = 4
var velocity = Vector3.ZERO
var speed = 0
var walk_speed = 10
var cart_walk_speed = 2

const ACCEL_SPEED = 1
var accel = 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	OS.set_window_size(Vector2(1000, 500))
	OS.set_window_position(Vector2(0,0))

func _physics_process(delta):
	# quit the game if esc pressed
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
	
	if Input.is_key_pressed(KEY_F11):
		OS.window_fullscreen = true
	
	# block destruction
	var space_state = get_world().direct_space_state
	var start = camera.global_transform.origin
	var end = camera.global_transform.origin + -camera.global_transform.basis.z * 10
	var result = space_state.intersect_ray(start, end, [self], 1)
	
	if result:
		var hit_collider = result.collider
		var hit_pos = result.position
		var hit_normal = result.normal
		
		global_immediate_geometry.begin = hit_pos
		global_immediate_geometry.end = hit_pos + hit_normal * 10
		global_immediate_geometry.draw()
		
		if hit_collider.get_class() == 'GridMap':
			var cell_pos = Vector3(ceil(hit_pos.x),ceil(hit_pos.y),ceil(hit_pos.z)) - (hit_normal)
	
			if Input.is_action_just_pressed('lmb'):
				print('destroy cell item ' + str(hit_collider.get_cell_item(cell_pos.x, cell_pos.y, cell_pos.z)))
				print('hit pos: ' + str(hit_pos) + ', cell_pos: ' + str(cell_pos) + ', normal: ' + str(hit_normal))
				hit_collider.set_cell_item(cell_pos.x, cell_pos.y, cell_pos.z, -1, 0)
			#elif Input.is_action_just_pressed('rmb'):
			#	var n = result.normal
			#	var new_pos = hit_collider.world_to_map(cell_pos + n*0.6)
			#	hit_collider.set_cell_item(new_pos.x, new_pos.y, new_pos.z, 1, 0)
			#	print('before ' + str(cell_pos) + ', after: ' + str(new_pos))
	#
	
	mouse_sens_multiplier = default_sens_multiplier
	speed = walk_speed
	
	velocity.y += gravity * delta * gravity_multiplier
	#velocity = Vector3.ZERO
	
	# set the acceleration value
	if get_input_direction() != Vector3.ZERO:
		accel = lerp(accel, ACCEL_SPEED, delta * 1.5)
	else:
		accel = lerp(accel, 0, delta * 100)
	
	var desired_velocity = get_input_direction() * speed * accel
	
	velocity.x = desired_velocity.x
	velocity.z = desired_velocity.z
	
	if Input.is_action_just_pressed('jump') and is_on_floor():
		velocity.y = jump_height
	
	
	#if Input.is_action_pressed('ascend'):
	#	velocity.y = jump_height
	#elif Input.is_action_pressed('descend'):
	#	velocity.y = -jump_height
	
	
	velocity = move_and_slide(velocity, Vector3.UP, true)

func _input(event):
	if (event is InputEventMouseMotion):
		camera.rotation_degrees.x -= event.relative.y * mouse_sens * mouse_sens_multiplier
		#raycast.rotation_degrees.x -= event.relative.y * mouse_sens * mouse_sens_multiplier
		rotation_degrees.y -= event.relative.x * mouse_sens * mouse_sens_multiplier
		
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




