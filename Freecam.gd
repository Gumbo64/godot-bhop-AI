extends Spatial

var speed = 20

var accel = 10
var jump = 2

var cam_accel = 40
var mouse_sense = 0.4
var snap

var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

onready var head = $Head
onready var camera = $Head/Camera

func _ready():
	#hides the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



onready var raycast = $Head/Camera/RayCast
onready var mainnode = get_node("/root/Main/")
onready var BHOP_CURRENT = get_node("/root/Main/BHOP_CURRENT")
onready var FP = get_node("/root/Main/GoalPoint")
func fire():
	if Input.is_action_just_pressed("fire"):
#		var body = bodynode.instance()
#		body.global_transform.origin = Vector3(0,150,0)
		if raycast.is_colliding():
			get_node("/root/Main/GoalPoint").global_transform.origin = raycast.get_collision_point()
			BHOP_CURRENT.nav_index=0
			cfg['startstate']= BHOP_CURRENT.get_state()
			mainnode.reset_logic()
#		anim_player.play("AssaultFire")
	if Input.is_action_just_pressed("rightfire"):
			if raycast.is_colliding():
				global_transform.origin = raycast.get_collision_point() + Vector3(0,10,0)
#		anim_player.play("AssaultFire")
	else:
		pass
#		camera.translation = Vector3.ZERO
#		anim_player.stop()

func _input(event):
	#get mouse input for camera rotation
#	fire()
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

#func _process(delta):
##	fire()
#	#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
#	if Engine.get_frames_per_second() > Engine.iterations_per_second:
#		camera.set_as_toplevel(true)
#		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, cam_accel * delta)
#		camera.rotation.y = rotation.y
#		camera.rotation.x = head.rotation.x
#	else:
#		camera.set_as_toplevel(false)
#		camera.global_transform = head.global_transform
		
func _physics_process(delta):
	#get keyboard input
	if cfg['camera_selected'] == "freecam": 
		fire()
		direction = Vector3.ZERO
		var h_rot = global_transform.basis.get_euler().y
		var f_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
		var h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
		
		#jumping and gravity
	#	if is_on_floor():
	#		snap = -get_floor_normal()
	#		accel = ACCEL_DEFAULT
	#		gravity_vec = Vector3.ZERO
	#	else:
	#		snap = Vector3.DOWN
	#		accel = ACCEL_AIR
	#		gravity_vec += Vector3.DOWN * gravity * delta
			
		if Input.is_action_pressed("jump") :
			snap = Vector3.ZERO
			velocity.y += jump
		if Input.is_action_pressed("crouch"):
			velocity.y -= jump
		
		#make it move
		velocity = velocity.linear_interpolate(direction * speed, accel * delta)
		 
		global_transform.origin += velocity
		velocity = Vector3.ZERO
	
	
