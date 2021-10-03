extends Spatial


onready var CAMERA = get_node("/root/Main/follow/Camera")
onready var BHOP_CURRENT = get_node("/root/Main/BHOP_CURRENT")
onready var BHOP_FUTURE = get_node("/root/Main/BHOP_FUTURE")
onready var BHOP_VISIBLE = get_node("/root/Main/BHOP_VISIBLE")
onready var FP = get_node("/root/Main/GoalPoint")

onready var nav = get_node("/root/Main/Navigation")
onready var nav_index_visualiser = get_node("/root/Main/nav_index_visualiser")

var Q = {}




class monte_node:
#	leaf node, terminal, terminal state are all the same thing
	var terminal = false
	var totalreward = 0
	var visits = 0
	var state
	
	func avg_score():
		return totalreward/visits



func rollout(path):
	
	if Q[path].terminal:
		return Q[path].totalreward/Q[path].visits
	
#	print(path)
	var t = load_path(path)
	#	if t[1] or path_timeout_check(path,0):
	if t[1] or (path_timeout_check(path,0) and cfg['timeouts']):
		Q[path].terminal = true
		return t[0]
#	load_state(state)
	var done = false
	var reward
	var score=t[0]

#	if done

#	trailsreset(BHOP_FUTURE.global_transform.origin,"rollout")
	var rollout_timeout = 0
	while !done and rollout_timeout < cfg['rollout_timeout']:
		var tmpaction = randi()%cfg['n_actions']
		for ____i in range(cfg['multistep']):
			t = BHOP_FUTURE.step(tmpaction)
			score += t[0]
			if t[1]:
				break
#		trails(BHOP_FUTURE.global_transform.origin,"rollout")
		rollout_timeout+=1
		done= t[1] or (path_timeout_check(path,0) and cfg['timeouts'])
	


	return score

#	Selection
func traverse():
	var path = []
#		will reach a node that hasn't been rollouted yet / has no visits / not created yet (those all mean the same thing btw)
	while Q[path].visits != 0 and !Q[path].terminal and path.size()<cfg['max_depth']:
		var i = best_uct_action(path)
#		var i = rand_action(path)
		path.push_back(i)

#	Q[path].set_children()
#	print(path.size())
	return path

func backpropagate(reward,path):
	var currentpath = []
	for i in path:
		currentpath.push_back(i)
#		print(Q[currentpath].state)
		
		Q[currentpath].totalreward += reward 
		Q[currentpath].visits +=1


func load_path(path):
#		reset to root node's position, then work through path
	var t = [0,false]
	var size = path.size()
	if size == 0:
		BHOP_FUTURE.load_state(BHOP_CURRENT.get_state())
		Q[path].state = BHOP_FUTURE.get_state()
		return t
	if size == 1:
		BHOP_FUTURE.load_state(BHOP_CURRENT.get_state())
		for ____j in range(cfg['multistep']):
			t = BHOP_FUTURE.step(path[0])
			if t[1]:
				Q[path].state = BHOP_FUTURE.get_state()
				return t
		
		Q[path].state = BHOP_FUTURE.get_state()
		return t
	
	var loadpath = path.slice(0,path.size()-2)
	var newaction = path[-1]
#	print([path,loadpath,newaction])
	BHOP_FUTURE.load_state(Q[loadpath].state)
	for ____j in range(cfg['multistep']):
		t = BHOP_FUTURE.step(newaction)
		if t[1]:
			Q[path].state = BHOP_FUTURE.get_state()
			return t

	Q[path].state = BHOP_FUTURE.get_state()
	return t
#
#	BHOP_FUTURE.load_state(BHOP_CURRENT.get_state())
#
#
#
#	trailsreset(BHOP_FUTURE.global_transform.origin,"loadpath")
#	for i in path:
#		for ____j in range(cfg['multistep']):
#
#			t = BHOP_FUTURE.step(i)
#			if t[1]:
#				return t
#		trails(BHOP_FUTURE.global_transform.origin,"loadpath")
#
#	return t




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
#	print(reward)
	return reward + c*sqrt(logPvisits/visits)





func best_action(path):
	var action = 0
	for i in range(cfg['n_actions']):
#		if Q[path+[i]].avg_score()>Q[path+[action]].avg_score():
		if Q[path+[i]].visits>Q[path+[action]].visits:
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
	"current":[BHOP_CURRENT.global_transform.origin,Color(0,1,1)],
	"navpath":[BHOP_CURRENT.global_transform.origin,Color(1,1,0)]
}
func trailsreset(newpos,caller):
	trail_dict[caller][0]=newpos
	
func trails(newpos,caller):
	if !cfg['trails']:
		return
	var callerstats = trail_dict[caller]
	Lines3D.DrawLine(callerstats[0] - Vector3(0,2.5,0), newpos - Vector3(0,2.5,0) ,callerstats[1],cfg['trails_time'])
	trail_dict[caller][0]=newpos


func new_node(newpath):
	Q[newpath]=monte_node.new()


#after performing an action, calling this recycles the tree
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
	iterations+=n

#func rand_action(path):
#	var i = randi() % 2
#	var newpath = path+[i]
#	if not Q.has(newpath):
#		new_node(newpath)
#	return i

static func path_timeout_check(path,n):
	return ((path.size()+n) * cfg['multistep']) >= cfg['max_game_length'] 

func currentstep(x):
	var t
	for i in range(cfg['multistep']):
		t = BHOP_CURRENT.step(x)
#		var reward = t[0]
#		var done=t[1]
		totalscore += t[0]
		if t[1]:
			break
#		trails(BHOP_CURRENT.global_transform.origin,"current")
	return t[1]


#All the paths and their data


var action = 0

func reset_logic():
	at_destination=false
	splitcounter = cfg['multistep']
	navpath_reset()
	Q = {}
	new_node([])
	Q[[]].totalreward =1
	Q[[]].visits =1


func reset_game():
	cfg['stepcount'] = 0
	reset_logic()
	BHOP_CURRENT.reset()
	
	totalscore=0
	iterate(cfg['iterations_per_step'])
	



func navpath_reset():
	cfg['navpath'] = nav.get_simple_path(cfg['startstate'][0],FP.global_transform.origin)
	navpath_distances_reset()

func navpath_distances_reset():
	var sum = 0

#	lastpoint is used to compare the distance between the 'current' node in the loop and the last node
#	goal point
	var lastpoint = FP.global_transform.origin
	var nav_reversed = cfg['navpath']
	nav_reversed.invert()
#	clears array and sets the last distance to 0  (distance from the finish to the finish)
	cfg['navpath_distances_to_end']=[0]
	for i in range(1,cfg['navpath'].size()):
		cfg['navpath_distances_to_end'].push_back( cfg['navpath_distances_to_end'][i-1] + (nav_reversed[i-1]-nav_reversed[i]).length() )
	
	cfg['navpath_distances_to_end'].invert()
	

func shownav():
	if BHOP_CURRENT.nav_index < cfg['navpath'].size():
		nav_index_visualiser.global_transform.origin = cfg['navpath'][BHOP_CURRENT.nav_index]
	else:
		nav_index_visualiser.global_transform.origin = FP.global_transform.origin
	trailsreset(cfg['navpath'][0],"navpath")
	for i in cfg['navpath']:
		trails(i,"navpath")
	

var highscore = -99999999
var totalscore = 0
var iterations = 0
var deaths = 0


var splitcounter = cfg['multistep']
func new_move_split():
	splitcounter -=1
	if splitcounter==0:
		return true
	return false

func _ready():
#	cfg['spawnpos'] = get_node("/root/Main/BHOP_CURRENT").global_transform.origin
#	cfg['BHOP_lastdistance']=cfg['BHOP_startdistance']
	randomize()
	reset_game()

var at_destination = false
func _physics_process(_delta):
	shownav()
#	trailsreset(BHOP_FUTURE.global_transform.origin,"current")
	if not at_destination:
		iterate(ceil(cfg['iterations_per_step']/cfg['multistep']))
		if new_move_split():
			
			BHOP_VISIBLE.load_state(BHOP_CURRENT.get_state())
			action = best_action([])
	#		var done = currentstep(action)
			BHOP_CURRENT.load_state(Q[[action]].state)
			
			shift_tree(action)
				
			splitcounter=cfg['multistep']

	
		cfg['stepcount']+=1
		if BHOP_VISIBLE.step(action)[2]:
			at_destination=true
			BHOP_VISIBLE.load_state(BHOP_CURRENT.get_state())
#			CAMERA.reset()

		
		
#	Lines3D.DrawLine(BHOP_VISIBLE.global_transform.origin - Vector3(0,2.5,0),FP.global_transform.origin ,Color(0,1,1),0)
		

	

	

	
		

	
	
	




