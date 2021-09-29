extends RichTextLabel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var BHOP_CURRENT = get_node("/root/Main/BHOP_CURRENT")
onready var player = get_node("/root/Main/playable")
onready var main = get_node("/root/Main/")

# Called when the node enters the scene tree for the first time.

var main_variables = ["highscore","iterations","deaths","totalscore"]\



func _process(delta):
	var totaltext = "Controls:\nQ to play\nE for flying\nE for following\nWASD to move\nSpace/Shift to move vertically\nLeft click to set goal point\nRight click to teleport\n"
	var state = BHOP_CURRENT.get_state()
	totaltext += "Goals completed" + ": " + str(state[3]) + "/"+str(cfg['navpath'].size()) + "\n"
	totaltext += "Your speed" + ": " + str((player.playerVelocity*Vector3(1,0,1)).length()) +"\n"
	totaltext += "Bot's speed" + ": " + str((state[2]*Vector3(1,0,1)).length()) +"\n"
	totaltext += "Camera" + ": " + str(cfg['camera_selected']) +"\n"
	
	set_text(totaltext)
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
