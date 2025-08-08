extends Area2D

@onready var game_manager = %GameManager
@onready var animation_player = $AnimationPlayer

func _on_body_entered(body):
	if body.has_method("get_player_id"):
		var player_id = body.get_player_id()
		game_manager.add_point(player_id)
	animation_player.play("pickup")
