extends RichTextLabel


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var playernode = get_node("/root/Spatial/Player")
# Called when the node enters the scene tree for the first time.
func _process(delta):
	set_text(str(playernode.playerVelocity) + "\n" + str(playernode.playerVelocity.length()) + "\n" +  str(playernode.wishJump))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
