class_name DemoSceneBase
extends XRToolsSceneBase

@export var basic_map: Node3D  # Exporting the BasicMap node.

var ground_mesh: MeshInstance3D
var ground_size: Vector3
var ground_center: Vector3

func _ready():
	super()

	var xr_interface: XRInterface

	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")

	# Ensure basic_map is assigned (possibly by exporting it or assigning via script)
	if not basic_map:
		push_error("basic_map is not assigned.")
		return

	# Attempt to get the Ground node under BasicMap
	if not basic_map.has_node("Ground"):
		push_error("Ground node not found under BasicMap.")
		return

	var ground = basic_map.get_node("Ground")

	# Try to get the MeshInstance3D
	if not ground.has_node("MeshInstance3D"):
		push_error("MeshInstance3D not found under Ground.")
		return

	ground_mesh = ground.get_node("MeshInstance3D") as MeshInstance3D

	if ground_mesh and ground_mesh.mesh:
		var local_aabb = ground_mesh.mesh.get_aabb()
		var global_scale = ground_mesh.global_transform.basis.get_scale()
		var aabb_size = local_aabb.size
		var aabb_position = ground_mesh.global_transform.origin + local_aabb.position * global_scale


		# Calculate the transformed corners of the AABB
		var transformed_aabb = AABB(aabb_position, aabb_size)

		ground_size = transformed_aabb.size
		ground_center = transformed_aabb.position + transformed_aabb.size * 0.5

		print("Ground size:", ground_size)
		print("Ground center:", ground_center)

		spawn_enemy()
	else:
		push_error("ground_mesh is not a valid MeshInstance3D or has no mesh.")




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

func is_spawnpoint_clear(spawn_point: Node3D, exclude_colliders := []) -> bool:
	var area: Area3D = spawn_point.get_node("Area3D")
	var shape_node: CollisionShape3D = area.get_node("CollisionShape3D")
	
	if not shape_node or not shape_node.shape:
		push_error("CollisionShape3D or its shape is missing!")
		return false

	var shape = shape_node.shape
	var transform = shape_node.global_transform

	# Debugging output
	print("Checking spawn point at position:", spawn_point.global_transform.origin)
	print("Collision shape transform:", transform.origin)
	print("Excluded colliders:", exclude_colliders)

	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = transform
	query.exclude = [area, spawn_point] + exclude_colliders
	query.collision_mask = area.collision_mask  # Optional

	var result = get_world_3d().direct_space_state.intersect_shape(query)

	if result.size() > 0:
		print("Spawn point blocked by:", result)
	else:
		print("Spawn point is clear.")

	return result.size() == 0




func spawn_enemy():
	#var max_attempts = 10
	#var attempt = 0
	var enemy_spawned = false
	

	while !enemy_spawned:
		#attempt += 1

		# Choose a random point within bounds
		var rand_x = randf_range(ground_center.x - ground_size.x/2, ground_center.x + ground_size.x/2)
		var rand_z = randf_range(ground_center.z - ground_size.y/2, ground_center.z + ground_size.y/2)

		var ray_origin = Vector3(rand_x, 1000, rand_z)
		var ray_target = Vector3(rand_x, -1000, rand_z)

		# Create ray query
		var query = PhysicsRayQueryParameters3D.new()
		query.from = ray_origin
		query.to = ray_target

		print("Attempting raycast from", ray_origin, "to", ray_target)

		var result = get_world_3d().direct_space_state.intersect_ray(query)

		if result and result.collider:
			print("Ray hit:", result.collider.name, "Groups:", result.collider.get_groups())

			if result.collider.is_in_group("ground"):
				var spawn_pos = result.position
				print("Ground hit at:", spawn_pos)
				var spawn_point = preload("res://assets/Indicator/SpawnPoint.tscn").instantiate()
				var enemy_node = get_tree().get_current_scene().find_child("Enemy", true, false)
				if enemy_node:
					enemy_node.add_child(spawn_point)
					spawn_point.global_position = spawn_pos
					print("Spawned successfully at:", spawn_point.global_position)
					if !is_spawnpoint_clear(spawn_point, [result.collider]):
						spawn_point.queue_free()
						print("Spawn overlap detected. Retrying...")
					else:
						enemy_spawned = true
					# Set reference to self (GrapplingDemo) dynamically
					if "grappling_demo_path" in spawn_point:
						spawn_point.grappling_demo_path = get_path()
						if spawn_point.has_meta("grappling_demo_path") and spawn_point.grappling_demo_path != NodePath(""):
							print("grappling_demo_path is assigned:", spawn_point.grappling_demo_path)
						else:
							print("grappling_demo_path is NOT assigned")
					else:
						push_error("grappling_demo_path not defined in SpawnPoint script.")


				else:
					push_error("Enemy node not found.")

			else:
				print("Ray hit non-ground object:", result.collider.name)
		else:
			print("Raycast failed to hit anything.")

	#print("Failed to spawn enemy after", max_attempts, "attempts.")
