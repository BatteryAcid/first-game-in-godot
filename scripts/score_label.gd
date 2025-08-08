extends Label
    

func _ready():
    var gm = get_tree().get_current_scene().get_node("GameManager")
    var player = get_tree().get_first_node_in_group("players")
    var player_id = null
    if player and player.has_method("get_player_id"):
        player_id = player.get_player_id()
    if gm and player_id != null:
        gm.connect("score_updated", Callable(self, "_on_score_updated"))
        _on_score_updated(player_id, gm.get_score(player_id))


func _on_score_updated(player_id, new_score):
    var player = get_tree().get_first_node_in_group("players")
    if player and player.has_method("get_player_id") and player.get_player_id() == player_id:
        text = str(new_score) + " Points"
