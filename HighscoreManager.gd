extends Node

signal data_recieved(data, type)
signal timeout(type)

enum WAIT_FOR {
	NOTHING,
	HIGHSCORE_FOR_PLAYER,
	HIGHSCORE_FOR_PLACE,
	HIGHSCORE_FOR_PLACES
}

# set in config file under [Highscore]
var private_key
var public_key
var host = "https://www.kitchen-games.de"

var confog_file_path = "res://config.cfg"

#the password file is encrypted to prevent cheating
var highscore_file = "user://encrypted_score.json"
var highscore_file_encryption_pass = "zzshuannxuwornvggvbsndjhsajcbisjdjafeqefsk"

var player_id = null
var adjectives = ["sweet","cute","sassy","giant","neat","hot","small","lumpy","clean","lucky","drunk","nice","huge","shiny","icy","juicy","crazy","new","bored","messy","silly","fancy","hard","solid","slimy","flashy","pretty","boring","odd","ill","easy","grumpy","cuddly","mixed","red","green","blue","purple","golden","yellow","orange","tiny","tense","brave","narrow","first","young","old","jazzy","wise"]
var nouns = ["stranger","tomato","buyer","cousin","orange","bread","error","mum","dad","virus","salad","dragon","actor","mom","girl","pie","lady","guy","cheese","pizza","user","engine","wife","singer","coffee","potato","tea","basket","steak","man","woman","death","breath","sir","king","queen","tomato","insect","hair","honey","person","writer"]

var http_request
var waiting_for = WAIT_FOR.NOTHING
var time_out_timer


func _ready():
	load_config()
	time_out_timer = Timer.new()
	time_out_timer.wait_time = 3
	time_out_timer.connect("timeout", self, "on_timeout")
	add_child(time_out_timer)
	http_request = HTTPRequest.new()
	http_request.connect("request_completed", self, "_on_request_completed")
	add_child(http_request)
	if !File.new().file_exists(highscore_file):
		make_local_highscore_file()
	player_id = load_player_id()
	
	sync_global_score()
	

func load_config():
	var config = ConfigFile.new()
	config.load(confog_file_path)
	
	private_key = config.get_value("Highscore", "private_key", private_key)
	public_key = config.get_value("Highscore", "public_key", public_key)
	host = config.get_value("Highscore", "host", host)
	nouns = config.get_value("Highscore", "nouns", nouns)
	adjectives = config.get_value("Highscore", "adjectives", adjectives)
	highscore_file_encryption_pass = config.get_value("Highscore", "highscore_file_encryption_pass", highscore_file_encryption_pass)
	
	
func _on_request_completed(_result, response_code, _headers, body):
	if response_code != 200 or waiting_for == WAIT_FOR.NOTHING:
		return
	
	var json = JSON.parse(body.get_string_from_utf8())
	emit_signal("data_recieved", json.result, waiting_for)
	time_out_timer.stop()
	waiting_for = WAIT_FOR.NOTHING
	
	
func on_timeout():
	emit_signal("timeout", waiting_for)

# function to synch the global and the local score, in case the highscore was beaten when playing online
func sync_global_score():
	connect("data_recieved", self, "_on_sync_data_recieved")
	var player_id = load_player_id()
	get_highscore_for_player(player_id)
	
	
func _on_sync_data_recieved(data, data_type):
	var player_id = load_player_id()
	var local_score = load_local_highscore()
	if data[0].score < local_score:
		submit_highscore(local_score)
		
	disconnect("data_recieved", self, "_on_sync_data_recieved")
	
	
func load_player_id():
	var file = File.new()
	file.open_encrypted_with_pass(highscore_file, File.READ, highscore_file_encryption_pass)
	var data = parse_json(file.get_as_text())
	return data.player_id


func load_local_highscore():
	var file = File.new()
	file.open_encrypted_with_pass(highscore_file, File.READ, highscore_file_encryption_pass)
	var data = parse_json(file.get_as_text())
	return data.highscore
	
	
func save_local_highscore(score):
	var file = File.new()
	if file.open_encrypted_with_pass(highscore_file, File.WRITE, highscore_file_encryption_pass) != 0:
		print("Error opening file")
		return

	file.store_line(to_json({"player_id": player_id, "highscore": score}))
	file.close()
	
	
func generate_player_id():
	randomize()
	return adjectives[randi() % adjectives.size()] + " and " + adjectives[randi() % adjectives.size()] + " " + nouns[randi() % nouns.size()]


func make_local_highscore_file():
	player_id = generate_player_id()
	save_local_highscore(0)


func get_highscore_for_player(_player_id, befor = 0, after = 0):
	var url = host + "/get_entry.php?key=" + str(public_key)  + "&name=" + _player_id.http_escape() + "&befor=" + str(befor) + "&after=" + str(after)
	http_request.cancel_request()
	var _err = http_request.request(url)
	waiting_for = WAIT_FOR.HIGHSCORE_FOR_PLAYER
	time_out_timer.start()
	
	
func get_highscore_for_places(from, to):
	from = max(from, 1)
	var url = host + "/get_entries.php?key=" + str(public_key)  + "&from=" + str(from) + "&to=" + str(to)
	http_request.cancel_request()
	var _err = http_request.request(url)
	waiting_for = WAIT_FOR.HIGHSCORE_FOR_PLACES
	time_out_timer.start()
	
	
func submit_highscore(highscore):
	http_request.cancel_request()
	var url = str(host + "/submit_entry.php?key=" + str(private_key) + "&name=" + player_id.http_escape() + "&score=" + str(highscore))
	var _err = http_request.request(url, ["User-Agent: Pirulo/1.0 (Godot)","Accept: */*"], true, HTTPClient.METHOD_GET)

	waiting_for = WAIT_FOR.NOTHING
