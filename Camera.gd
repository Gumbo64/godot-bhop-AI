# 99% stolen from
# https://kidscancode.org/godot_recipes/3d/interpolated_camera/


extends Camera

export var lerp_speed = 3.0
export var target_path = "/root/Main/BHOP_VISIBLE"
#export (Vector3) var offset = Vector3.ZERO
export (Vector3) var offset = Vector3(0,10,10)

onready var freecam = get_node("/root/Main/Freecam/")
onready var mainnode = get_node("/root/Main/")
onready var FP = get_node("/root/Main/GoalPoint")

onready var BHOP_FUTURE = get_node("/root/Main/BHOP_FUTURE")



var target = null
var spawnpos

var freefly = false



func _ready():
	spawnpos = global_transform.origin 
	if target_path:
		target = get_node(target_path)

func _physics_process(delta):
	if Input.is_action_just_pressed("freeflytoggle"):
		freefly = !freefly
		current = freefly
		if !current:
			freecam.global_transform= global_transform
	if !target:
		return
	else:
		var target_pos = target.global_transform.translated(offset)
		global_transform = global_transform.interpolate_with(target_pos, lerp_speed * delta)
		look_at(target.global_transform.origin, Vector3.UP)
	
	
func reset():
	global_transform.origin=spawnpos
