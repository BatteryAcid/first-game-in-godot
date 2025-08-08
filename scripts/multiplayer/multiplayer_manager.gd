extends Node

const BASE_PORT = 8080
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_PLAYERS_PER_SERVER = 2
const DISCOVERY_PORT = 8079
const BROADCAST_INTERVAL = 2.0

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")

var _players_spawn_node
var host_mode_enabled = false
var multiplayer_mode_enabled = false
var respawn_point = Vector2(30, 20)

var target_server_host = DEFAULT_SERVER_IP
var target_server_port = BASE_PORT

var auto_start_multiplayer = false

var current_player_count = 0

var broadcast_socket: PacketPeerUDP
var broadcast_timer: Timer
var server_name = "Godot LAN Game"

func become_host():
	print("Starting host on port %d!" % target_server_port)
	
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	
	multiplayer_mode_enabled = true
	host_mode_enabled = true
	current_player_count = 0
	
	var server_peer = ENetMultiplayerPeer.new()
	var port_to_try = target_server_port
	var max_attempts = 10
	var attempts = 0
	var error
	
	# Try to find an available port
	while attempts < max_attempts:
		error = server_peer.create_server(port_to_try, MAX_PLAYERS_PER_SERVER)
		
		if error == OK:
			print("Successfully created server on port %d" % port_to_try)
			target_server_port = port_to_try  # Update to the actual port we're using
			break
		else:
			print("Port %d is busy, trying %d..." % [port_to_try, port_to_try + 1])
			port_to_try += 1
			attempts += 1
	
	if error != OK:
		print("Failed to create server after %d attempts. Last error: %s" % [max_attempts, error])
		return false
	
	multiplayer.multiplayer_peer = server_peer
	
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	
	_remove_single_player()
	
	if not OS.has_feature("dedicated_server"):
		_add_player_to_game(1)
	
	# Start server broadcasting
	_start_server_broadcasting()
	
	return true
	
func join_as_player_2():
	_remove_single_player()
	print("Joining server at %s:%d" % [target_server_host, target_server_port])
	
	multiplayer_mode_enabled = true
	
	var client_peer = ENetMultiplayerPeer.new()
	var error = client_peer.create_client(target_server_host, target_server_port)
	
	if error != OK:
		print("Failed to connect to server: %s" % error)
		return false
	
	multiplayer.multiplayer_peer = client_peer

	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
		
	return true

func _add_player_to_game(id: int):
	if current_player_count >= MAX_PLAYERS_PER_SERVER:
		print("Server full! Cannot add player %d" % id)
		return
	
	print("Player %s joined the game!" % id)
	
	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)

	_players_spawn_node.add_child(player_to_add, true)
	current_player_count += 1

	if host_mode_enabled:
		call_deferred("_force_resync_for_new_peer", id)
	
	print("Current players: %d/%d" % [current_player_count, MAX_PLAYERS_PER_SERVER])
	
	if current_player_count >= MAX_PLAYERS_PER_SERVER:
		print("Server full, stopping broadcasts")
	if host_mode_enabled:
		_resync_all_players.rpc()

@rpc("any_peer", "call_local") 
func _resync_all_players():
	print("Resyncing all players...")
	
func _force_resync_for_new_peer(new_peer_id: int):
	print("Forcing resync for new peer: %d" % new_peer_id)
	# Remove e re-adiciona todos os players para forçar replicação
	var players_data = []
	
	for child in _players_spawn_node.get_children():
		players_data.append({
			"id": int(child.name),
			"position": child.position
		})
		child.queue_free()
	
	await get_tree().process_frame
	for data in players_data:
		var player_to_add = multiplayer_scene.instantiate()
		player_to_add.player_id = data.id
		player_to_add.name = str(data.id)
		player_to_add.position = data.position
		_players_spawn_node.add_child(player_to_add, true)

func _del_player(id: int):
	print("Player %s left the game!" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()
	current_player_count = max(0, current_player_count - 1)
	
	print("Current players: %d/%d" % [current_player_count, MAX_PLAYERS_PER_SERVER])
	
	if host_mode_enabled and current_player_count < MAX_PLAYERS_PER_SERVER and not broadcast_timer:
		print("Server has available slots, resuming broadcasts")
		_start_server_broadcasting()
	
func _remove_single_player():
	print("Remove single player")
	var player_to_remove = get_tree().get_current_scene().get_node("Player")
	if player_to_remove:
		player_to_remove.queue_free()

func _start_server_broadcasting():
	print("Starting server broadcasting")
	broadcast_socket = PacketPeerUDP.new()
	
	broadcast_socket.set_broadcast_enabled(true)
	print("Broadcast mode enabled on socket")
	
	broadcast_timer = Timer.new()
	broadcast_timer.wait_time = BROADCAST_INTERVAL
	broadcast_timer.timeout.connect(_broadcast_server)
	broadcast_timer.autostart = true
	add_child(broadcast_timer)
	
	print("Broadcast timer created with interval: %f seconds" % BROADCAST_INTERVAL)
	
	_broadcast_server()

func _broadcast_server():
	if not host_mode_enabled or not broadcast_socket:
		print("Broadcast skipped - host_mode_enabled: %s, broadcast_socket: %s" % [host_mode_enabled, broadcast_socket != null])
		return
	
	if current_player_count < MAX_PLAYERS_PER_SERVER:
		var display_name = "%s (Port %d)" % [server_name, target_server_port]
		
		var message = "SERVER_AVAILABLE:%d:%d:%d:%s" % [
			target_server_port, 
			current_player_count, 
			MAX_PLAYERS_PER_SERVER, 
			display_name
		]
		
		print("Broadcasting message: %s" % message)
		
		broadcast_socket.set_dest_address("255.255.255.255", DISCOVERY_PORT)
		var result = broadcast_socket.put_packet(message.to_utf8_buffer())
		
		if result == OK:
			print("Broadcast sent successfully to 255.255.255.255")
		else:
			print("Broadcast failed with error: %s" % result)
		
		print("Broadcasting server: %s" % message)
	else:
		print("Server full (%d/%d), not broadcasting" % [current_player_count, MAX_PLAYERS_PER_SERVER])

func _stop_server_broadcasting():
	if broadcast_timer:
		broadcast_timer.queue_free()
		broadcast_timer = null
	
	if broadcast_socket:
		broadcast_socket.close()
		broadcast_socket = null
	
	print("Stopped server broadcasting")

func shutdown_multiplayer():
	_stop_server_broadcasting()
	multiplayer_mode_enabled = false
	host_mode_enabled = false
	current_player_count = 0
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	
	
	
	
	
	
	
	
	
	
