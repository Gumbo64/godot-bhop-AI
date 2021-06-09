extends KinematicBody

var damage = 10
const MAX_CAM_SHAKE = 0.001

onready var b_decal = preload("res://BulletDecal.tscn")

#var speed = 100
var accel_type = {"default": 30, "air": 30}
onready var accel = accel_type["default"]
var gravity = 40
var jump = 20

var cam_accel = accel_type['default'] * 10000
var mouse_sense = 0.1
var snap

var direction = Vector3()
var velocity = Vector3()
var gravity_vec = Vector3()
var movement = Vector3()

onready var head = $Head
onready var camera = $Head/Camera
var full_contact = false
var h_velocity = Vector3()
onready var ground_check = $GroundCheck
onready var anim_player = $AnimationPlayer
onready var raycast = $Head/Camera/RayCast

#var accelDir
#: normalized direction that the player has requested to move (taking into account the movement keys and look direction)
#var prevVelocity
#: The current velocity of the player, before any additional calculations
#var accelerate = 1
#: The server-defined player acceleration value
#var max_velocity= 500
#: The server-defined maximum player velocity (this is not strictly adhered to due to strafejumping)
var max_velocity_ground = 50000
var max_velocity_air = 50000

var friction = 5
func Accelerate(accelDir, prevVelocity, accelerate, max_velocity,delta):
	var projVel = prevVelocity.dot( accelDir); 
	var accelVel = accelerate * delta; 
#    // If necessary, truncate the accelerated velocity so the vector projection does not exceed max_velocity
	if(projVel + accelVel > max_velocity):
		accelVel = max_velocity - projVel;

	return prevVelocity + accelDir * accelVel;


func MoveGround(accelDir, prevVelocity,delta):
#    // Apply Friction
	var speed = prevVelocity.length();
	if (speed != 0):
		var drop = speed * friction * delta;
		prevVelocity *= max(speed - drop, 0) / speed; 
#		// Scale the velocity based on friction.
	

#    // ground_accelerate and max_velocity_ground are server-defined movement variables
	return Accelerate(accelDir, prevVelocity, accel_type["default"], max_velocity_ground,delta);


func MoveAir(accelDir, prevVelocity, delta):
#    // air_accelerate and max_velocity_air are server-defined movement variables
	return Accelerate(accelDir, prevVelocity, accel_type['air'], max_velocity_air, delta);

func _ready():
	#hides the cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sense))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sense))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
		
func fire():
	if Input.is_action_pressed("fire"):
		if not anim_player.is_playing():
#			camera.translation = lerp(camera.translation, 
#					Vector3(rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE), 
#					rand_range(MAX_CAM_SHAKE, -MAX_CAM_SHAKE), 0), 0.5)
			if raycast.is_colliding():
				var target = raycast.get_collider()
				if target.is_in_group("Enemy"):
					target.health -= damage
				var b = b_decal.instance()
				raycast.get_collider().add_child(b)
				b.global_transform.origin = raycast.get_collision_point()
				b.look_at(raycast.get_collision_point() + raycast.get_collision_normal(), Vector3.UP)
#		anim_player.play("AssaultFire")
	else:
		pass
#		camera.translation = Vector3.ZERO
#		anim_player.stop()
		
		
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

	#get keyboard input
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	var f_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	#jumping and gravity
	#make it move
#	velocity = velocity.linear_interpolate(direction * speed, accel * delta)

	

	if is_on_floor():
		
		h_velocity = MoveGround(direction,h_velocity ,delta )
		
		snap = -get_floor_normal()
		accel = accel_type["default"]
		gravity_vec = Vector3.ZERO
		
	else:
		h_velocity = MoveAir(direction,h_velocity ,delta )
		snap = Vector3.DOWN
		accel = accel_type["air"]
		gravity_vec += Vector3.DOWN * gravity * delta
	if Input.is_action_pressed("jump") and is_on_floor():
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * jump
		
	
	movement = h_velocity + gravity_vec
#	h_velocity = velocity
	move_and_slide_with_snap(movement, snap, Vector3.UP)
	if(global_transform.origin[1]<0):
		global_transform.origin[1] = 50
	

	
	

