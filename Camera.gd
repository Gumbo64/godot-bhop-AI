# 99% stolen from
# https://kidscancode.org/godot_recipes/3d/interpolated_camera/


extends Camera

export var lerp_speed = 3.0
export (NodePath) var target_path = "/root/Main/BHOP_VISIBLE"
export (Vector3) var offset = Vector3.ZERO

var target = null
var spawnpos
func _ready():
	spawnpos = global_transform.origin 
	if target_path:
		target = get_node(target_path)

func _physics_process(delta):
	if !target:
		return
	var target_pos = target.global_transform.translated(offset)
	global_transform = global_transform.interpolate_with(target_pos, lerp_speed * delta)
	look_at(target.global_transform.origin, Vector3.UP)
	
	
func reset():
	global_transform.origin=spawnpos
