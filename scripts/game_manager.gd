extends Node

signal score_updated(player_id, new_score)

var scores = {}

func _ready():
	print("Game Manager: Starting with target server %s:%d" % [MultiplayerManager.target_server_host, MultiplayerManager.target_server_port])
	print("Game Manager: Multiplayer mode enabled: %s, Host mode enabled: %s" % [MultiplayerManager.multiplayer_mode_enabled, MultiplayerManager.host_mode_enabled])
	
	if OS.has_feature("dedicated_server"):
		print("Starting dedicated server...")
		MultiplayerManager.become_host()
	elif MultiplayerManager.target_server_host != MultiplayerManager.DEFAULT_SERVER_IP or MultiplayerManager.target_server_port != MultiplayerManager.BASE_PORT:
		# We're joining a specific server from the server browser
		print("Auto-joining server from browser: %s:%d" % [MultiplayerManager.target_server_host, MultiplayerManager.target_server_port])
		var success = MultiplayerManager.join_as_player_2()
		if not success:
			print("Failed to join server, returning to browser")
			MultiplayerManager.target_server_host = MultiplayerManager.DEFAULT_SERVER_IP
			MultiplayerManager.target_server_port = MultiplayerManager.BASE_PORT
			get_tree().change_scene_to_file("res://scenes/server_browser.tscn")
	elif MultiplayerManager.multiplayer_mode_enabled:
		if MultiplayerManager.host_mode_enabled:
			print("Auto-starting as host from server browser")
			var success = MultiplayerManager.become_host()
			if not success:
				print("Failed to start server, returning to browser")
				get_tree().change_scene_to_file("res://scenes/server_browser.tscn")
		else:
			print("Auto-joining game from server browser")
			var success = MultiplayerManager.join_as_player_2()
			if not success:
				print("Failed to join server, returning to browser")
				get_tree().change_scene_to_file("res://scenes/server_browser.tscn")
	else:
		print("Game Manager: No multiplayer mode set, running in single player")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		back_to_main_menu()


func add_point(player_id):
	if not scores.has(player_id):
		scores[player_id] = 0
	scores[player_id] += 1
	emit_signal("score_updated", player_id, scores[player_id])


func get_score(player_id):
	return scores.get(player_id, 0)

func become_host():
	print("Become host pressed")
	MultiplayerManager.become_host()
	
func join_as_player_2():
	print("Join as player 2")
	MultiplayerManager.join_as_player_2()

func back_to_main_menu():
	print("Returning to main menu")
	if MultiplayerManager.multiplayer_mode_enabled:
		MultiplayerManager.shutdown_multiplayer()
	
	MultiplayerManager.target_server_host = MultiplayerManager.DEFAULT_SERVER_IP
	MultiplayerManager.target_server_port = MultiplayerManager.BASE_PORT
	
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
