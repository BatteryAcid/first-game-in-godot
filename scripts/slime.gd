extends Node2D

const SPEED = 60

var direction = 1

@onready var ray_cast_right = $RayCastRight
@onready var ray_cast_left = $RayCastLeft
@onready var animated_sprite = $AnimatedSprite2D

var last_sent_position = Vector2.ZERO

func _process(delta):
	if multiplayer.is_server():
		if ray_cast_right.is_colliding():
			direction = -1
			animated_sprite.flip_h = true
		if ray_cast_left.is_colliding():
			direction = 1
			animated_sprite.flip_h = false
		position.x += direction * SPEED * delta
		
		if position.distance_to(last_sent_position) > 0.5:
			rpc_id(0, "sync_position", position)
			last_sent_position = position

@rpc("any_peer")
func sync_position(new_pos: Vector2):
	if not multiplayer.is_server():
		position = new_pos
