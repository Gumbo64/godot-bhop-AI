extends Spatial

var cfg ={
	"n_actions":2,
	"C_exploration":2,
	"iterations_per_step":20,
	"multistep":5
}
onready var BHOP_CURRENT = get_node("/root/Main/BHOP_CURRENT")
onready var BHOP_FUTURE = get_node("/root/Main/BHOP_FUTURE")
var Q = {}


func future_reset():
	BHOP_FUTURE.load_state(BHOP_CURRENT.get_state())



class monte_node:
#	leaf node, terminal, terminal state are all the same thing
	var terminal = false
	var totalreward = 0
	var visits = 0
	var children = {}
	var path=[]
	func _init(_path):
		path = _path

	func set_children():
		if terminal:
			children = {}
			return print("NO CHILDREN TO MAKE")
#		n_actions = 2
		for i in range(2):
			children[i]=path+[i]








func rollout(path):


#	load_state(state)
	var done = false
	var t
	var reward
	var score=0
	t = load_path(path)
#	if done
	if t[1]:
		Q[path].terminal = true
		return t[0]
	var oldpos
	oldpos = BHOP_FUTURE.global_transform.origin
	while !done:
		var tmpaction = randi()%cfg['n_actions']
		for ____i in range(cfg['multistep']):
			t = BHOP_FUTURE.step(tmpaction)
			score += t[0]
			if t[1]:
				break
		done= t[1]
		
		var newpos = BHOP_FUTURE.global_transform.origin
		Lines3D.DrawLine(oldpos,newpos , Color(0, 1, 1),0.0)
		oldpos = newpos

	return score

#	Selection
func traverse():
	var path = []
#		will reach a node that hasn't been rollouted yet / has no visits / not created yet (those all mean the same thing btw)
	while Q[path].visits != 0:
		var i = best_uct_action(path)
#		var i = rand_action(path)
		path.push_back(i)

	Q[path].set_children()

	return path

func backpropagate(reward,path):
	var currentpath = []
	for i in path:
		currentpath = Q[currentpath].children[i]
#		get average
		Q[currentpath].totalreward += reward 
		Q[currentpath].visits +=1

func multistep(xaction,path):


	var done = false
	var t

	var score=0

#		cfg['multistep']
#	print([xaction,path])

	t = load_path(path)
#	if done
	if t[1]:
		Q[path].terminal = true
		return [t[0],true]


	for _i in range(cfg['multistep']):

		t = BHOP_FUTURE.step(xaction)
		score += t[0]
		done = t[1]
		if (done):
			return [score,done]

	return [score,done]

func load_path(path):
#		reset to root node's position, then work through path

	BHOP_FUTURE.load_state(BHOP_CURRENT.get_state())
	var oldpos
	oldpos = BHOP_FUTURE.global_transform.origin
	var t = [0,false]
	for i in path:
		for ____j in range(cfg['multistep']):
			t = BHOP_FUTURE.step(i)
			print(____j)
			if t[1]:
				return t
		var newpos = BHOP_FUTURE.global_transform.origin
		Lines3D.DrawLine(oldpos,newpos , Color(1, 1, 0),0.0)
		oldpos = newpos
	return t




func best_uct_action(path):
	var best_child = 0
#		log of the parent's visits
	var logPvisits = log(Q[path].visits)

#		return action with best UCT value
	for i in range(cfg['n_actions']):
		var newpath = path+[i]
		if not Q.has(newpath):
			new_node(newpath)
			return i

		var childreward = Q[newpath].totalreward / Q[newpath].visits
		var childvisits = Q[newpath].visits
		if uct_with_log(childreward,logPvisits,childvisits) > uct_with_log(Q[path+[best_child]].totalreward,logPvisits,Q[path+[best_child]].visits):
			best_child=i
	return best_child
	
func rand_action(path):
	var i = randi() % 2
	var newpath = path+[i]
	if not Q.has(newpath):
		new_node(newpath)


	return i

static func uct_with_log(reward,logPvisits,visits):
	return reward + 2*sqrt(logPvisits/visits)


func best_action():
	var action = 0
	for i in range(cfg['n_actions']):
		if Q[[i]].visits>Q[[action]].visits:
			action = i
	return action

#func check_terminal(path):
#	for i in range(cfg['n_actions']):
##			if it lives even once then it's fine (not terminal)
#
#		if not multistep(i,path)[1]:
#			Q[path].terminal=false
#			return
#	Q[path].terminal=true

func new_node(newpath):
	Q[newpath]=monte_node.new(newpath)

var action

#All the paths and their data
func _ready():
	pass



#
func _physics_process(_delta):
	
	Q = {}
	new_node([])
	Q[[]].totalreward =1
	Q[[]].visits =1
	Q[[]].set_children()

	for i in range(floor(cfg['iterations_per_step'])):
		var path = traverse()
		var reward = rollout(path)
		backpropagate(reward,path)
	action = best_action()
#	print(action)
	for i in range(cfg['multistep']):
		var t = BHOP_CURRENT.step(action)
#		var reward = t[0]
#		var done=t[1]
		if (t[1]):
			BHOP_CURRENT.reset()
			break
#	print(traverse())




