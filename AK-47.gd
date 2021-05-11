extends KinematicBody

var damage = 10
const MAX_CAM_SHAKE = 0.3



var speed = 40
var accel_type = {"default": 10, "air": 1}
onready var accel = accel_type["default"]
var gravity = 40
var jump = 20

var cam_accel = 40
var mouse_sense = 0.1
var snap

var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

onready var head = $Head
onready var camera = $Head/Camera
var h_acceleration = 6
var air_acceleration = 1
var normal_acceleration = 6
var full_contact = false
var h_velocity = Vector3()
onready var ground_check = $GroundCheck
onready var anim_player = $AnimationPlayer
onready var raycast = $Head/Camera/RayCast

func _ready():
	#hides the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensimoustivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
		
func fire():
	if Input.is_action_pressed("fire"):
		if not anim_player.is_playing():
			camera.translation = lerp(camera.translation, 
					Vector3(rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE), 
					rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE), 0), 0.5)
			if raycast.is_colliding():
				var target = raycast.get_collider()
				if target.is_in_group("Enemy"):
					target.health -= damage
		anim_player.play("AssaultFire")
	else:
		camera.translation = Vector3()
		anim_player.stop()
		
		
func _process(delta):
	#camera physics interpolation to reduce physics jitter on high refresh-rate monitors
	if Engine.get_frames_per_second() > Engine.iterations_per_second:
		camera.set_as_toplevel(true)
		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, cam_accel * delta)
		camera.rotation.y = rotation.y
		camera.rotation.x = head.rotation.x
	else:
		camera.set_as_toplevel(false)
		camera.global_transform = head.global_transform		

func _physics_process(delta):
	
	fire()
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	var f_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	#jumping and gravity
	if is_on_floor():
		snap = -get_floor_normal()
		accel = accel_type["default"]
		gravity_vec = Vector3.ZERO
		
	else:
		snap = Vector3.DOWN
		accel = accel_type["air"]
		gravity_vec += Vector3.DOWN * gravity * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * jump
	
	#make it move
	velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	movement = velocity + gravity_vec
	
	move_and_slide_with_snap(movement, snap, Vector3.UP)
	
	
	
	
	
	
	
	
	
	
	
	
