# 99% stolen from
# https://kidscancode.org/godot_recipes/3d/interpolated_camera/


extends Camera

export var lerp_speed = 3.0
export var target_path = "/root/Main/BHOP_VISIBLE"
#export (Vector3) var offset = Vector3.ZERO
export (Vector3) var offset = Vector3(0,10,10)


onready var mainnode = get_node("/root/Main/")
onready var FP = get_node("/root/Main/GoalPoint")

onready var raycast = $RayCast
onready var parent = get_parent()

var target = null
var spawnpos

var freefly = false
func fire():
	if Input.is_action_just_pressed("fire"):

#		var body = bodynode.instance()
#		body.global_transform.origin = Vector3(0,150,0)
		if raycast.is_colliding():
			get_node("/root/Main/GoalPoint").global_transform.origin = raycast.get_collision_point()
			cfg['BHOP_startdistance']=((cfg['BHOP_spawnpos'] - FP.global_transform.origin)*Vector3(1,0,1)).length()
#		anim_player.play("AssaultFire")
	if Input.is_action_just_pressed("rightfire"):
		if raycast.is_colliding():
			global_transform.origin = raycast.get_collision_point() + Vector3(0,10,0)

var xMouseSensitivity = 1
var yMouseSensitivity = 1
func _input(event):
	if event is InputEventMouseMotion and freefly:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		rotate_y(deg2rad(-event.relative.x * xMouseSensitivity))
#		parent.rotate_x(deg2rad(-event.relative.y * yMouseSensitivity))
#		parent.rotation.x = clamp(parent.rotation.x, deg2rad(-89), deg2rad(89))
		

func _ready():
	spawnpos = global_transform.origin 
	if target_path:
		target = get_node(target_path)

func _physics_process(delta):
	if Input.is_action_just_pressed("freeflytoggle"):
		rotation.x=0
		freefly = !freefly
	
	
	if freefly or !target:
		fire()
		var movement_vector = Vector3.ZERO
		if Input.is_action_pressed("move_forward"):
			movement_vector.z -= 1
		if Input.is_action_pressed("move_backward"):
			movement_vector.z += 1
		if Input.is_action_pressed("move_left"):
			movement_vector.x -= 1
		if Input.is_action_pressed("move_right"):
			movement_vector.x += 1
		if Input.is_action_pressed("jump"):
			movement_vector.y += 1
		if Input.is_action_pressed("crouch"):
			movement_vector.y -= 1
		
		movement_vector = movement_vector.rotated(Vector3.UP, global_transform.basis.get_euler().y)
		global_transform.origin+=(movement_vector)
		
	else:
		var target_pos = target.global_transform.translated(offset)
		global_transform = global_transform.interpolate_with(target_pos, lerp_speed * delta)
		look_at(target.global_transform.origin, Vector3.UP)
	
	
func reset():
	if !freefly:
		global_transform.origin=spawnpos
