extends Control

signal join_requested(server_info: Dictionary)

var server_info: Dictionary

@onready var server_name_label = %ServerName
@onready var server_info_label = %ServerInfo
@onready var join_button = %JoinButton

func setup_server_info(info: Dictionary):
	server_info = info
	
	server_name_label.text = info.server_name
	server_info_label.text = "Players: %d/%d | %s:%d" % [
		info.player_count, 
		info.max_players, 
		info.ip, 
		info.port
	]
	
	join_button.disabled = info.player_count >= info.max_players

func _on_join_pressed():
	if server_info and server_info.player_count < server_info.max_players:
		join_requested.emit(server_info)
