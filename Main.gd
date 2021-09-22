extends Spatial


onready var CAMERA = get_node("/root/Main/Camera")
onready var BHOP_CURRENT = get_node("/root/Main/BHOP_CURRENT")
onready var BHOP_FUTURE = get_node("/root/Main/BHOP_FUTURE")
onready var BHOP_VISIBLE = get_node("/root/Main/BHOP_VISIBLE")
var Q = {}




class monte_node:
#	leaf node, terminal, terminal state are all the same thing
	var terminal = false
	var totalreward = 0
	var visits = 0
	
	func avg_score():
		return totalreward/visits



func rollout(path):

	var t = load_path(path)
#	load_state(state)
	var done = false
	var reward
	var score=t[0]

#	if done
	if t[1]:
		Q[path].terminal = true
		return t[0]
#	trailsreset(BHOP_FUTURE.global_transform.origin,"rollout")
	var timeout = 0
	while !done and timeout < cfg['timeout']:
		var tmpaction = randi()%cfg['n_actions']
		for ____i in range(cfg['multistep']):
			t = BHOP_FUTURE.step(tmpaction)
			score += t[0]
			if t[1]:
				break
		done= t[1]
#		trails(BHOP_FUTURE.global_transform.origin,"rollout")
		timeout+=1
	


	return score

#	Selection
func traverse():
	var path = []
#		will reach a node that hasn't been rollouted yet / has no visits / not created yet (those all mean the same thing btw)
	while Q[path].visits != 0:
		var i = best_uct_action(path)
#		var i = rand_action(path)
		path.push_back(i)

#	Q[path].set_children()

	return path

func backpropagate(reward,path):
	var currentpath = []
	for i in path:
		currentpath.push_back(i)
		
		Q[currentpath].totalreward += reward 
		Q[currentpath].visits +=1


func load_path(path):
#		reset to root node's position, then work through path

	BHOP_FUTURE.load_state(BHOP_CURRENT.get_state())
	var t = [0,false]
	trailsreset(BHOP_FUTURE.global_transform.origin,"loadpath")
	for i in path:
		for ____j in range(cfg['multistep']):
			t = BHOP_FUTURE.step(i)
			if t[1]:
				return t
		trails(BHOP_FUTURE.global_transform.origin,"loadpath")

	return t




func best_uct_action(path):
	var best_child = 0
#		log of the parent's visits
	var logPvisits = log(Q[path].visits)

#		return action with best UCT value
	if not Q.has(path+[0]) and not Q.has(path+[1]):
		best_child = randi()%2
		new_node(path+[best_child])
		return best_child
		
	for i in range(cfg['n_actions']):
		var newpath = path+[i]
		if not Q.has(newpath):
			new_node(newpath)
			return i

		if uct_with_log(Q[newpath].avg_score(),logPvisits,Q[newpath].visits,cfg['C_exploration']) > uct_with_log(Q[path+[best_child]].avg_score(),logPvisits,Q[path+[best_child]].visits,cfg['C_exploration']):
			best_child=i
	return best_child

static func uct_with_log(reward,logPvisits,visits,c):
	return reward + c*sqrt(logPvisits/visits)

func rand_action(path):
	var i = randi() % 2
	var newpath = path+[i]
	if not Q.has(newpath):
		new_node(newpath)


	return i




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

onready var trail_dict={
	"rollout":[BHOP_CURRENT.global_transform.origin,Color(0,1,1)],
	"loadpath":[BHOP_CURRENT.global_transform.origin,Color(1,1,0)],
	"current":[BHOP_CURRENT.global_transform.origin,Color(0,1,1)]
}
func trailsreset(newpos,caller):
	trail_dict[caller][0]=newpos
	
func trails(newpos,caller):
	var callerstats = trail_dict[caller]
	Lines3D.DrawLine(callerstats[0] - Vector3(0,2.5,0), newpos - Vector3(0,2.5,0) ,callerstats[1],1)
	trail_dict[caller][0]=newpos


func new_node(newpath):
	Q[newpath]=monte_node.new()


#after performing an action, calling this recycles the 
func shift_tree(x):
#	the path is the index remember
	var new_Q = {}
	for path in Q.keys():
		if path and path[0] == x:
#			cut out the first action from the path
			var newpath = path.slice(1,path.size())
			new_Q[newpath]=Q[path]
#		otherwise it just doesn't get copied
	Q = new_Q
		
		





func iterate(n):
	for i in range(n):
		var path = traverse()
		var reward = rollout(path)
		backpropagate(reward,path)



func currentstep(x):
	var t
	for i in range(cfg['multistep']):
		t = BHOP_CURRENT.step(x)
#		var reward = t[0]
#		var done=t[1]
		totalscore += t[0]
		if (t[1]):
			break
		trails(BHOP_CURRENT.global_transform.origin,"current")
	return t[1]


#All the paths and their data


var action = 0

func reset_tree():
	Q = {}
	new_node([])
	Q[[]].totalreward =1
	Q[[]].visits =1

var camerareset = true
func reset_game():
	reset_tree()
	BHOP_CURRENT.reset()
	camerareset=true

	totalscore=0
	iterate(cfg['iterations_per_step'])
	
	
	
var highscore = -99999999
var totalscore = 0

var splitcounter = cfg['multistep']
func new_move_split():
	splitcounter -=1
	if splitcounter==0:
		splitcounter=cfg['multistep']
		return true
	return false

func _ready():
	randomize()
	reset_game()

func _physics_process(_delta):
#	trailsreset(BHOP_FUTURE.global_transform.origin,"current")
	iterate(ceil(cfg['iterations_per_step']/cfg['multistep']))
	if new_move_split():
		if camerareset:
			camerareset=false
			
		BHOP_VISIBLE.load_state(BHOP_CURRENT.get_state())
		action = best_action()
		var done = currentstep(action)
	#	if it died, reset tree otherwise just shift
		if !done:
			shift_tree(action)
		else:
			if totalscore>highscore:
				highscore = totalscore
				print("High score: ",highscore)
			reset_game()
			
	if BHOP_VISIBLE.step(action)[1]:
		BHOP_VISIBLE.load_state(BHOP_CURRENT.get_state())
		CAMERA.reset()
		

	

	

	
		

	
	
	




