class_name DemoSceneBase
extends XRToolsSceneBase

@export var basic_map: Node3D  # Exporting the BasicMap node.

var ground_mesh: MeshInstance3D
var ground_size: Vector3
var ground_center: Vector3

func _ready():
	super()

	var webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		XRToolsUserSettings.webxr_primary_changed.connect(self._on_webxr_primary_changed)
		_on_webxr_primary_changed(XRToolsUserSettings.get_real_webxr_primary())
		if basic_map:
		# Find the Ground node (child of BasicMap)
			var ground = basic_map.get_node("Ground")
			
			# If Ground node exists, get its MeshInstance3D
			if ground:
				ground_mesh = ground.get_node("MeshInstance3D")
				
				if ground_mesh and ground_mesh is MeshInstance3D:
					var aabb = ground_mesh.get_transformed_aabb()
					ground_size = aabb.size
					ground_center = aabb.position + aabb.size * 0.5

					# Print size and center
					print("Ground size:", ground_size, " | Center:", ground_center)


func _on_webxr_primary_changed(webxr_primary: int) -> void:
	# Default to thumbstick.
	if webxr_primary == 0:
		webxr_primary = XRToolsUserSettings.WebXRPrimary.THUMBSTICK

	# Re-assign the action name on all the applicable functions.
	var action_name = XRToolsUserSettings.get_webxr_primary_action(webxr_primary)
	for controller in [$XROrigin3D/LeftHand, $XROrigin3D/RightHand]:
		for n in ["MovementDirect", "MovementTurn", "FunctionTeleport"]:
			var f = controller.get_node_or_null(n)
			if f:
				if "input_action" in f:
					f.input_action = action_name
				if "rotation_action" in f:
					f.rotation_action = action_name

func is_spawnpoint_clear(spawn_point: Node3D) -> bool:
	var area = spawn_point.get_node("Area3D")
	var space_state = get_world_3d().direct_space_state

	var shape = area.get_shape(0)
	var transform = area.global_transform

	var result = space_state.intersect_shape(PhysicsShapeQueryParameters3D.new().apply({
		shape = shape,
		transform = transform,
		collision_mask = area.collision_layer, # Adjust if needed
		exclude = [area],
	}))

	return result.size() == 0


func spawn_enemy():
	var max_attempts = 10
	var attempt = 0

	while attempt < max_attempts:
		attempt += 1

		# Choose a random point within bounds
		var rand_x = randf_range(ground_center.x - ground_size.x/2, ground_center.x + ground_size.x/2)
		var rand_z = randf_range(ground_center.z - ground_size.z/2, ground_center.z + ground_size.z/2)


		var ray_origin = Vector3(rand_x, 1000, rand_z)
		var ray_target = Vector3(rand_x, -1000, rand_z)

		var query = PhysicsRayQueryParameters3D.new()
		query.from = ray_origin
		query.to = ray_target

		var result = get_world_3d().direct_space_state.intersect_ray(query)


		if result and result.collider.is_in_group("ground"):
			var spawn_pos = result.position

			var spawn_point = preload("res://assets/Indicator/SpawnPoint.tscn").instantiate()
			spawn_point.global_transform.origin = spawn_pos

			if is_spawnpoint_clear(spawn_point):
				get_node("Enemy").add_child(spawn_point)
				print("Spawned successfully at:", spawn_pos)
				return
			else:
				spawn_point.queue_free() # Discard and try again
				print("Spawn overlap detected. Retrying...")

	print("Failed to spawn enemy after", max_attempts, "attempts.")
