extends Node

#var cfg ={
var n_actions=2

var C_exploration= 2
var iterations_per_step=20
var multistep=10
var rollout_timeout=6

#in steps
var timeouts = false
var max_game_length=2000

var stepcount = 0

var graceperiod = 10
var minmovement = 0.01

var stop_movement_distance = 10

var trails = true
var trails_time = 0.0166

var lastpos = Vector3.ZERO
var startstate = [Vector3(-216.373,86.808,319.672),Vector3.ZERO,Vector3(0,0,20),0]



var navpath
var navpath_distances_to_end = []
var nav_index_min_range = 10
#var navpath_cut_factor = 5



var camera_selected = "follow"


#}
