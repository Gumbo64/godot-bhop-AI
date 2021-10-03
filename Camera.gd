# 99% stolen from
# https://kidscancode.org/godot_recipes/3d/interpolated_camera/


extends Camera

export var lerp_speed = 5.0
export var target_path = "/root/Main/BHOP_VISIBLE"
#export (Vector3) var offset = Vector3.ZERO
export (Vector3) var offset = Vector3(0,10,10)

onready var freecam = get_node("/root/Main/freecam/")
onready var mainnode = get_node("/root/Main/")
onready var FP = get_node("/root/Main/GoalPoint")

onready var BHOP_FUTURE = get_node("/root/Main/BHOP_FUTURE")
onready var Player = get_node("/root/Main/playable")



var target = null
var spawnpos

var freefly = false



func _ready():
	current = true
	spawnpos = global_transform.origin 
	if target_path:
		target = get_node(target_path)

func _physics_process(delta):
	if Input.is_action_just_pressed("freecam"):
		cfg['camera_selected'] = "freecam"
		freecam.head.get_node("Camera").current=true
#		freecam.global_transform.origin= global_transform.origin
#		freecam.head.rotation.x = rotation.x
#		freecam.rotation.y = rotation.y
#		freecam.rotation.z = rotation.z
	if Input.is_action_just_pressed("playable"):
		cfg['camera_selected'] = "playable"
		Player.camera.current = true
	if Input.is_action_just_pressed("follow"):
		cfg['camera_selected'] = "follow"
		current=true
#		if cfg['freefly'] and !cfg['playable']:
#				freecam.head.get_node("Camera").current=true
#				freecam.global_transform.origin= global_transform.origin
#				freecam.head.rotation.x = rotation.x
#				freecam.rotation.y = rotation.y
#				freecam.rotation.z = rotation.z
			
	if !target:
		return
	else:
		var target_pos = target.global_transform.translated(offset)
		global_transform = global_transform.interpolate_with(target_pos, lerp_speed * delta)
		look_at(target.global_transform.origin, Vector3.UP)
	
	
func reset():
	global_transform.origin=spawnpos
