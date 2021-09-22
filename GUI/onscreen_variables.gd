extends RichTextLabel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#onready var AI = get_node("/root/Main/AI")
onready var main = get_node("/root/Main/")

# Called when the node enters the scene tree for the first time.

var onscreen_variables = ["highscore","iterations","deaths","steps"]


func _process(delta):
	var totaltext = ""
	for i in onscreen_variables:
		totaltext += i + ": " + str(main[i]) + "\n"
	set_text(totaltext)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
