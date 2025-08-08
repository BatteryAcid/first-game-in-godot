extends Control

func _ready():
	pass

func _on_singleplayer_pressed():
	print("Starting singleplayer game")
	MultiplayerManager.multiplayer_mode_enabled = false
	MultiplayerManager.host_mode_enabled = false
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_multiplayer_pressed():
	get_tree().change_scene_to_file("res://scenes/server_browser.tscn")

func _on_quit_pressed():
	get_tree().quit()
