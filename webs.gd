extends Node3D

func _ready():
	# Align with ground
	print("Web spawned at: ", global_position)
	# Visual debug - draw axes
	DebugDraw3D.draw_arrow(global_position, global_position + Vector3.UP, Color.WHITE, 2.0)
	DebugDraw3D.draw_arrow(global_position, global_position + Vector3.FORWARD, Color.BLUE, 2.0)
	DebugDraw3D.draw_arrow(global_position, global_position + Vector3.RIGHT, Color.RED, 2.0)
	var ray = RayCast3D.new()
	add_child(ray)
	ray.target_position = Vector3(0, -2, 0)
	ray.force_raycast_update()
	if ray.is_colliding():
		global_transform.origin = ray.get_collision_point()
	ray.queue_free()
	
	# Start decay timer
	$Timer.start(4.5)  # Slightly before enemy release

func _on_timer_timeout():
	queue_free()
