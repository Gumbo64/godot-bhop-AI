extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in self.get_children():
		i.get_child(0).name = i.name
		print(i.name)
		print(i.get_child(0).name)
	print('Renamed map')



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
