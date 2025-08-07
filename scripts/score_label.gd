extends Label
    

func _ready():
    var gm = get_tree().get_current_scene().get_node("GameManager")
    var player = _get_local_player()
    var player_id = null
    
    if player and player.has_method("get_player_id"):
        player_id = player.get_player_id()
    
    if gm and player_id != null:
        gm.connect("score_updated", Callable(self, "_on_score_updated"))
        _on_score_updated(player_id, gm.get_score(player_id))

func _get_local_player():
    # Para singleplayer, pega o nó Player direto
    if not MultiplayerManager.multiplayer_mode_enabled:
        return get_tree().get_current_scene().get_node_or_null("Player")
    else:
        # Para multiplayer, pega da group "players"
        return get_tree().get_first_node_in_group("players")

func _on_score_updated(player_id, new_score):
    var player = _get_local_player()
    if player and player.has_method("get_player_id") and player.get_player_id() == player_id:
        text = str(new_score) + " Points"
