extends Area2D

@onready var timer = $Timer

func _on_body_entered(body):
	if not body.has_method("mark_dead") or not body.has_method("get") or not body.has_method("set"):
		return
	if not MultiplayerManager.multiplayer_mode_enabled:
		Engine.time_scale = 0.5
		body.get_node("CollisionShape2D").queue_free()
		timer.start()
	else:
		if multiplayer.is_server():
			_multiplayer_dead(body)
		else:
			request_player_death.rpc(body.name)

@rpc("any_peer")
func request_player_death(player_name):
	var players_node = get_tree().get_current_scene().get_node("Players")
	if players_node.has_node(player_name):
		var player = players_node.get_node(player_name)
		if player and player.alive:
			_multiplayer_dead(player)

func _multiplayer_dead(body):
	if body.alive:
		Engine.time_scale = 0.5
		body.mark_dead()

func _on_timer_timeout():
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
