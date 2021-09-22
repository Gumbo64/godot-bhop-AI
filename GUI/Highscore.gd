extends RichTextLabel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#onready var AI = get_node("/root/Main/AI")
onready var main = get_node("/root/Main/")

# Called when the node enters the scene tree for the first time.
func _process(delta):
	set_text("Highscore: "+str(main.highscore)+"\n")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
