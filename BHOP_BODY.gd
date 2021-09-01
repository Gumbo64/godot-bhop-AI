extends KinematicBody

class_name BHOP_BODY
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
var spawnpos



#onready var AI = get_node("/root/Main/AI")
onready var AI = get_node("/root/AI")

#
#var AI = load("res://AI.py").new()

#var timespeed = 100
func _ready():
#	Engine.set_time_scale(timespeed)
	spawnpos = get_node("/root/Main/BHOP").global_transform.origin
	rewardtrackers['startdistance']=((global_transform.origin - FP.global_transform.origin)*Vector3(1,0,1)).length()
	rewardtrackers['lastdistance']=rewardtrackers['startdistance']
	#hides the cursor
#	spawnpos = global_transform.origin
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
#	for i in range(20):
#		raycast.add_exception(get_node("/root/Spatial/Player"))
#		raycast.add_exception(get_node("/root/Spatial/AI"))
	reset()
	score=0
	done=false
	reset()
	observation=sense()
#	AI.ready()
	
	
	

	
	

onready var feelers = $Feelers


var damage = 10

var snap
var gravity_vec = Vector3.ZERO
var direction
var velocity
var dotspeed
var wishjump = true




var scores = []
var avg_scores = []
var eps_history = []
var done=false
var score=0
var observation
var observation_
var reward
var info
var avg_score
var action 

func average(array):
	var sum = 0
	for num in array:
		sum += num
	return sum/array.size()

# newest/last x entries in array
func newest(array,x):
	var newarray=[]
	array = array.invert()
	for i in range(min(x,array.size())):
		newarray.push_back(array[i])
	return newarray
	
	

func _physics_process(delta):


	action = AI.get_action(observation)
	rewardtrackers['stepcount']+=1
#	print(action)
	var t = step(action)

	
	
	observation_ = t[0]
	reward = t[1]
	done=t[2]
	info= t[3]
	
	score += reward
#	print([observation,action,reward,observation_,done])
	AI.store_transition(observation,action,reward,observation_,done)
	AI.learn()
	observation=observation_
	if done:
		AI.died()

		print('Score: '+str(score))
		scores.push_back(score)
#		print(score)
#		eps_history.push_back(AI.get_epsilon())
		
#		avg_score=average(newest(scores,20))
#		avg_scores.push_back(avg_score)
		
		score=0
		done=false
		reset()
		observation=sense()
	pass
		


func getRaycastCollisions():
	var raycastarray = []
	var distance
	for i in feelers.get_children():
		if i.is_colliding():
			var origin = i.global_transform.origin
			var collision_point = i.get_collision_point()
#			Lines3D.DrawLine(i.global_transform.origin, collision_point, Color(0, 1, 0),0.0)
			distance = origin.distance_to(collision_point)
		else:
			distance = 50
		raycastarray.push_back(distance/50)
		
	return raycastarray
		

var output = [0]
# FP = Finish platform
onready var FP = get_node("/root/Main/Map/Finish/Finish")



#   this is the function to get inputs
func sense():
	var playerVelocity2D = Vector2(playerVelocity.x,playerVelocity.z)
	var FP_difference = FP.global_transform.origin-global_transform.origin
	FP_difference = Vector2(FP_difference.x,FP_difference.z)
	
#	var angle2platform = Vector2(global_transform.origin.x,global_transform.origin.z).angle_to(Vector2(FP.global_transform.origin.x,FP.global_transform.origin.z))
	# Remember velocity angle = player angle
#	var angledifference = rotation.y - angle2platform
	
	var sensearray = []
	
#	RELATIVE Velocity
#	Vertical, forward (only forward is needed since we are always facing the direction of velocity
	sensearray.push_back(playerVelocity.y/30)
	sensearray.push_back(playerVelocity2D.length()/40)
	
	
#	Platform/FP RELATIVE direction x and z (normalised vector)

#	forward
	var FP_direction = Vector2(FP_difference.dot(playerVelocity2D),FP_difference.dot((playerVelocity2D).rotated(deg2rad(-90)))).normalized()

	sensearray.push_back(FP_direction.y)
#	sideways
	sensearray.push_back(FP_direction.x)

#	Past information
	sensearray.push_back(actionbook[rewardtrackers['lastaction']][0])
	sensearray.push_back(actionbook[rewardtrackers['lastaction']][1])
	
#	Raycasts
	sensearray.append_array(getRaycastCollisions())
#	print(sensearray)
	return sensearray



var rewardtrackers = {
	'lastdistance': 0,
	'lastaction':0,
	'startdistance':0,
	'touchedplatforms':['plat1'],
	'stepcount':0
}

func distance_reward():
#	only rewards for horizontal distance not vertical since it can't really control that 
	var distance = ((global_transform.origin - FP.global_transform.origin)*Vector3(1,0,1)).length()

	var reward = 1-pow(distance/(rewardtrackers['startdistance']+10),0.4)
	
#	rewardtrackers['lastdistance']=distance

	return reward


func step(action):
	
	var s_observation_
	var finish_reward=0
	var s_done
	var s_info
	
	
#	print([action,(((action-2)/4.0)*2.0)])
	
	
	
	SetMovementDir(action)
	


	var deltat = 0.016667
	frameCount +=1

#	# Movement, here's the important part */
	QueueJump()
	if(is_on_floor()):
		snap = -get_floor_normal()
		GroundMove(deltat,wishdir)
	else:
		snap = Vector3.DOWN
		AirMove(deltat,wishdir)
	if wishJump and is_on_floor():
		snap = Vector3.ZERO
	move_and_slide_with_snap(playerVelocity,snap,Vector3.UP)
	if(global_transform.origin[1]<0):
		finish_reward += -100
		s_done = true
		
	else:
		for i in range(get_slide_count()):
			if (get_slide_collision(i).collider.name.left(6) == "Finish"  ):
				finish_reward = 10000
				s_done = true
				break
			elif(get_slide_collision(i).collider.name.left(3) == "Die" ):
				finish_reward = -100
				s_done = true
				break
			else:
				if(not rewardtrackers['touchedplatforms'].has(get_slide_collision(i).collider.name)):
					rewardtrackers['touchedplatforms'].push_back(get_slide_collision(i).collider.name)
					finish_reward += 50
				

			
#	Surfing
#	needs to be done after the finish/death collision detection because I'm pretty sure surfing works by pushing the player away from the surface, meaning it may not be actually touching anymore
	if get_slide_count():
		var collision = get_slide_collision(0)
		
#		this is the MAX angle to surf on
		var FLOOR_ANGLE_TOLERANCE = 60
		if ( wishjump and rad2deg(acos(collision.normal.dot(Vector3.UP))) <= FLOOR_ANGLE_TOLERANCE):
			var reflect = collision.remainder.bounce(collision.normal)
			playerVelocity = playerVelocity.bounce(collision.normal)
			move_and_slide_with_snap(reflect,snap,Vector3.UP)
		else:
			var remainder = collision.remainder.bounce(collision.normal)
			playerVelocity = playerVelocity.slide(collision.normal)
#			move_and_slide_with_snap(reflect,snap,Vector3.UP)

	
	s_observation_ = sense()
	
	finish_reward += distance_reward()
#	print(finish_reward)
#	finish_reward = distance_reward()
	return [s_observation_,finish_reward, s_done, s_info]
	
	




func reset():
	rewardtrackers['stepcount']=0
	rewardtrackers['touchedplatforms']=['plat1']
	rewardtrackers['lastdistance']=rewardtrackers['startdistance']
	global_transform.origin = spawnpos
	rotation = Vector3(0,PI,0)
	playerVelocity = Vector3(0,0,20)

##******************************************************************************************************\
#|* MOVEMENT
#\*******************************************************************************************************/
#
##*
# * Sets the movement direction based on player input
# */


var actionbook = {
	0:[0,1],
	1:[-1,0],
	2:[1,0],
	3:[0,-1],
	
	4:[1,-1],
	5:[-1,-1],
	6:[1,1],
	7:[-1,1]
}
func SetMovementDir(xaction):
#	
#	playerVelocity=(playerVelocity*100).round()/100

#	print(xaction)
	rotation = Vector3(0,atan2(playerVelocity.x,playerVelocity.z),0)
#	we swap sin and cos because I want 0 degrees to be directly up

	

	cmd.rightMove = actionbook[xaction][0]
	cmd.forwardMove = actionbook[xaction][1]
	
	rewardtrackers['lastaction']=xaction



##*
# * Queues the next jump just like in Q3
# */

func QueueJump():
	if(holdJumpToBhop):
		wishJump = wishjump
		return
	if(wishjump and !wishJump):
		wishJump = true
	if(wishjump):
		wishJump = false


##*
# * Execs when the player is in the air
# */
var wishdir
var wishvel

func AirMove(deltat,wishdir):

#	var wishdir = Vector3.ZERO
	var wishvel  = airAcceleration
	var accel 

#	SetMovementDir()


	
#	get_global_transform().basis)
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
	

	Accelerate(wishdir, wishspeed, accel,deltat)
	if(airControl > 0):
		AirControl(wishdir, wishspeed2,deltat)
	# !CPM: Aircontrol

	# Apply gravity
	playerVelocity.y -= gravity*deltat
	

	# LEGACY MOVEMENT SEE BOTTOM


##*
# * Air control occurs when the player is in the air, it allows
# * players to move side to side much faster rather than being
# * 'sluggish' when it comes to cornering.
# */
func AirControl(wishdir, wishspeed,deltat ):

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
	k *= airControl * dot * dot * deltat

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
func GroundMove(deltat,wishdir):
#	var wishdir = Vector3.ZERO
#	var wishvel = Vector3.ZERO

	# Do not apply friction if the player is queueing up the next jump
	if(!wishJump):
		ApplyFriction(1.0,deltat)
	else:
		ApplyFriction(0,deltat)

#	SetMovementDir()

	wishdir = Vector3(cmd.rightMove, 0, cmd.forwardMove)
	wishdir = wishdir.rotated(Vector3.UP, global_transform.basis.get_euler().y)
	wishdir = wishdir.normalized()
	moveDirectionNorm = wishdir

	var wishspeed = wishdir.length()
	wishspeed *= moveSpeed

	Accelerate(wishdir, wishspeed, runAcceleration,deltat)

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
func ApplyFriction(t ,deltat):
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
		drop = control * friction * deltat * t
	

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
func Accelerate(wishdir, wishspeed , accel ,deltat):
	var addspeed 
	var accelspeed 
	var currentspeed 

	currentspeed = playerVelocity.dot( wishdir)
	addspeed = wishspeed - currentspeed
	if(addspeed <= 0):
		return
	accelspeed = accel * deltat * wishspeed
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

