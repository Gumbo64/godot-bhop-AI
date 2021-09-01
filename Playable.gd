extends KinematicBody


#var playerView : Transform  
## Must be a camera
var playerViewYOffset = 0.6 
## The height at which the camera is bound to
var xMouseSensitivity = 0.4
var yMouseSensitivity = 0.4

## Frame occuring factors */
var gravity   = 20
var friction  = 6        
#        # Ground friction

## Movement stuff */
var moveSpeed               = 7
## Ground move speed
var runAcceleration         = 14   
## Ground accel
var runDeacceleration       = 10   
## Deacceleration that occurs when running on the ground
var airAcceleration         = 2.0  
## Air accel
var airDeacceleration       = 2.0    
## Deacceleration experienced when opposite strafing
var airControl              = 0.3  
## How precise air control is
var sideStrafeAcceleration  = 100
## How fast acceleration occurs to get up to sideStrafeSpeed when side strafing
var sideStrafeSpeed         = 2
## What the max speed to generate when side strafing
var jumpSpeed               = 12
## The speed at which the character's up axis gains when hitting jump
var holdJumpToBhop         = true
## When enabled allows player to just hold jump button to keep on bhopping perfectly. Beware: smells like casual.

var frameCount = 0
var dt = 0.0
var fps = 0.0

var rotX = 0.0
var rotY = 0.0

var moveDirection  = Vector3.ZERO
var moveDirectionNorm = Vector3.ZERO
var playerVelocity = Vector3.ZERO
var playerTopVelocity = 0.0


## Q3: players can queue the next jump just before he hits the ground
var wishJump = true



## Used to display real time friction values
var playerFriction = 0.0

## Contains the command the user wishes upon the character
var cmd =  {
	"rightMove": 0,
	"forwardMove":0
}
var spawnpos = Vector3.ZERO
func _ready():
	#hides the cursor
	
	spawnpos = global_transform.origin
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	raycast.add_exception(get_node("/root/Main/Player"))
	reset()
	
onready var head = $Head
onready var camera = $Head/Camera
var mousetoggle
func _input(event):
	if event.is_action_pressed("mousetoggle"):
		if mousetoggle:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mousetoggle = not mousetoggle
			
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * xMouseSensitivity))
		head.rotate_x(deg2rad(-event.relative.y * yMouseSensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
		
		
var cam_accel =  100
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
		
onready var b_decal = preload("res://BulletDecal.tscn")
onready var anim_player = $AnimationPlayer
onready var raycast = $Head/Camera/RayCast
var damage = 10
func fire():
	if Input.is_action_just_pressed("fire"):
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
				b.look_at(raycast.get_collision_point() + (raycast.get_collision_normal().cross(Vector3(0,1,0)) + raycast.get_collision_normal()*Vector3.UP).normalized(), Vector3.UP)
#				global_transform.origin = raycast.get_collision_point() + Vector3(0,10,0)
#		anim_player.play("AssaultFire")
	if Input.is_action_just_pressed("rightfire"):
			if raycast.is_colliding():
				global_transform.origin = raycast.get_collision_point() + Vector3(0,10,0)
#		anim_player.play("AssaultFire")
	else:
		pass
#		camera.translation = Vector3.ZERO
#		anim_player.stop()
		
var snap
var gravity_vec = Vector3.ZERO
var direction
var velocity
var dotspeed



func _physics_process(delta):
	fire()
	dt +=delta

#	# Movement, here's the important part */
	
	QueueJump()
	if(is_on_floor()):
		snap = -get_floor_normal()
#		print('ground')
		GroundMove(delta)
#		playerVelocity.y=0

	else:
#		print('air')
		snap = Vector3.DOWN
		AirMove(delta)
#		playerVelocity.y -=gravity
		# gravity_vec += Vector3.DOWN * gravity 
	if wishJump and is_on_floor():
		snap = Vector3.ZERO
#		gravity_vec = Vector3.UP * jumpSpeed
#	print(wishJump)
	# Move the controller
#	global_transform.origin += playerVelocity * delta

#	print(playerVelocity.y)
					
	move_and_slide_with_snap(playerVelocity,snap,Vector3.UP)
	
#	var collision = move_and_collide(playerVelocity*delta)
	for i in range(get_slide_count()):
		if (get_slide_collision(i).collider.name == "Finish" or get_slide_collision(i).collider.name[0] == "D"):
			reset()
			
#	This part is what happens when you
	if get_slide_count():
		
		var collision = get_slide_collision(0)
		
#		this is the MAX angle to surf on
		var FLOOR_ANGLE_TOLERANCE = 60
#		print([rad2deg(acos(collision.normal.dot(Vector3.UP))),FLOOR_ANGLE_TOLERANCE,rad2deg(acos(collision.normal.dot(Vector3.UP))) <= FLOOR_ANGLE_TOLERANCE])
		if ( Input.is_action_pressed("jump") and rad2deg(acos(collision.normal.dot(Vector3.UP))) <= FLOOR_ANGLE_TOLERANCE):
			var reflect = collision.remainder.bounce(collision.normal)
			playerVelocity = playerVelocity.bounce(collision.normal)
			move_and_slide_with_snap(reflect,snap,Vector3.UP)
		else:
			var remainder = collision.remainder.bounce(collision.normal)
			playerVelocity = playerVelocity.slide(collision.normal)
#			move_and_slide_with_snap(reflect,snap,Vector3.UP)



	if(global_transform.origin[1]<0):
		reset()
		
	#Need to move the camera after the player has been moved because otherwise the camera will clip the player if going fast enough and will always be 1 frame behind.
	# Set the camera's position to the transform
#	playerView.position = this.transform.position
#	playerView.position.y = this.transform.position.y + playerViewYOffset


func reset():
	global_transform.origin = spawnpos
	rotation = Vector3(0,PI,0)
	camera.rotation=Vector3.ZERO
	head.rotation=Vector3.ZERO
	playerVelocity = Vector3(0,0,20)

##******************************************************************************************************\
#|* MOVEMENT
#\*******************************************************************************************************/
#
##*
# * Sets the movement direction based on player input
# */
func SetMovementDir():
	cmd.forwardMove = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	cmd.rightMove = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")


##*
# * Queues the next jump just like in Q3
# */

func QueueJump():
	if(holdJumpToBhop):
		wishJump = Input.is_action_pressed("jump")
		return
	if(Input.is_action_pressed("jump") and !wishJump):
		wishJump = true
	if(Input.is_action_pressed("jump")):
		wishJump = false


##*
# * Execs when the player is in the air
# */
var wishdir
var wishvel

func AirMove(delta):

	var wishdir = Vector3.ZERO
	var wishvel  = airAcceleration
	var accel 

	SetMovementDir()


	
#	print(get_global_transform().basis)
	wishdir = Vector3(cmd.rightMove, 0, cmd.forwardMove)
	wishdir = wishdir.rotated(Vector3.UP, global_transform.basis.get_euler().y)
#	wishdir = to_global(wishdir)

	var wishspeed = wishdir.length()
	
	wishspeed *= moveSpeed

	wishdir = wishdir.normalized()
	moveDirectionNorm = wishdir

	# CPM: Aircontrol
	var wishspeed2 = wishspeed
	if(playerVelocity.dot( wishdir) < 0):
		accel = airDeacceleration
	else:
		accel = airAcceleration
	# If the player is ONLY strafing left or right
	if(cmd.forwardMove == 0 and cmd.rightMove != 0):
	
		if(wishspeed > sideStrafeSpeed):
			wishspeed = sideStrafeSpeed
		accel = sideStrafeAcceleration
	

	Accelerate(wishdir, wishspeed, accel,delta)
	if(airControl > 0):
		AirControl(wishdir, wishspeed2,delta)
	# !CPM: Aircontrol

	# Apply gravity
	playerVelocity.y -= gravity * delta
	

	# LEGACY MOVEMENT SEE BOTTOM


##*
# * Air control occurs when the player is in the air, it allows
# * players to move side to side much faster rather than being
# * 'sluggish' when it comes to cornering.
# */
func AirControl(wishdir, wishspeed,delta ):

	var zspeed 
	var speed  
	var dot    
	var k      
	var i  

	# Can't control movement if not moving forward or backward
	if(abs(cmd.forwardMove) < 0.001 or abs(wishspeed) < 0.001):
		return;

	zspeed = playerVelocity.y
	playerVelocity.y = 0
	# Next two lines are equivalent to idTech's Vectornormalized */
	speed = playerVelocity.length()
	playerVelocity=playerVelocity.normalized()

	dot = playerVelocity.dot( wishdir)
	k = 32
	k *= airControl * dot * dot * delta

	# Change direction while slowing down
	if(dot > 0):
	
		playerVelocity.x = playerVelocity.x * speed + wishdir.x * k
		playerVelocity.y = playerVelocity.y * speed + wishdir.y * k
		playerVelocity.z = playerVelocity.z * speed + wishdir.z * k

		playerVelocity=playerVelocity.normalized()
		moveDirectionNorm = playerVelocity
	
	playerVelocity.x *= speed
	playerVelocity.y = zspeed # Note this line
	playerVelocity.z *= speed



#*
# * Called every frame when the engine detects that the player is on the ground
# */
func GroundMove(delta):
	var wishdir = Vector3.ZERO
#	var wishvel = Vector3.ZERO

	# Do not apply friction if the player is queueing up the next jump
	if(!wishJump):
		ApplyFriction(1.0,delta)
	else:
		ApplyFriction(0,delta)

	SetMovementDir()

	wishdir = Vector3(cmd.rightMove, 0, cmd.forwardMove)
	wishdir = wishdir.rotated(Vector3.UP, global_transform.basis.get_euler().y)
	wishdir = wishdir.normalized()
	moveDirectionNorm = wishdir

	var wishspeed = wishdir.length()
	wishspeed *= moveSpeed

	Accelerate(wishdir, wishspeed, runAcceleration,delta)

	# Reset the gravity velocity
	playerVelocity.y = 0
	
	if(wishJump):

		playerVelocity.y =  jumpSpeed
		# only apply if it would make you go faster because going slower up a ramp is lame
		if ((playerVelocity+ get_floor_normal()*Vector3(1,0,1) * jumpSpeed).length() > playerVelocity.length() ):
			playerVelocity += get_floor_normal()*Vector3(1,0,1) * jumpSpeed
#		playerVelocity += get_floor_normal()*Vector3(1,0,1) * jumpSpeed
#		wishJump = false
	

#*
# * Applies friction to the player, called in both the air and on the ground
# */
func ApplyFriction(t ,delta):
	var vec= playerVelocity # Equivalent to: VectorCopy()
#	var vel 
	var speed 
	var newspeed 
	var control 
	var drop 

	vec.y = 0.0
	speed = vec.length()
	drop = 0.0

	# Only if the player is on the ground then apply friction */
	if(is_on_floor()):
		control = max(speed,runDeacceleration)
		drop = control * friction * delta * t
	

	newspeed = speed - drop
	playerFriction = newspeed
	if(newspeed < 0):
		newspeed = 0
	if(speed > 0):
		newspeed /= speed

	playerVelocity.x *= newspeed
#	playerVelocity.y *= newspeed
	playerVelocity.z *= newspeed


##*
# * Calculates wish acceleration based on player's cmd wishes
# */
func Accelerate(wishdir, wishspeed , accel ,delta):
	var addspeed 
	var accelspeed 
	var currentspeed 

	currentspeed = playerVelocity.dot( wishdir)
	addspeed = wishspeed - currentspeed
	if(addspeed <= 0):
		return
	accelspeed = accel * delta * wishspeed
	if(accelspeed > addspeed):
		accelspeed = addspeed

	playerVelocity.x += accelspeed * wishdir.x
	playerVelocity.z += accelspeed * wishdir.z





#func LateUpdate()
#{
#
#}

#func OnGUI()
#{
#	GUI.Label(Rect(0, 0, 400, 100), "FPS: " + fps, style)
#	var ups = controller.velocity
#	ups.y = 0
#	GUI.Label(Rect(0, 15, 400, 100), "Speed: " + Mathf.Round(ups.length() * 100) / 100 + "ups", style)
#	GUI.Label(Rect(0, 30, 400, 100), "Top Speed: " + Mathf.Round(playerTopVelocity * 100) / 100 + "ups", style)
#}

