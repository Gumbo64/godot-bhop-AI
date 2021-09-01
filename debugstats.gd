extends RichTextLabel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

#onready var AI = get_node("/root/Main/AI")
onready var AI = get_node("/root/AI")
# Called when the node enters the scene tree for the first time.
func _process(delta):
	set_text(str(AI.deathcount()))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
