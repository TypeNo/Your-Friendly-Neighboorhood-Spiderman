extends Node3D

@onready var area = $Area3D
@onready var collision = $Area3D/CollisionShape3D
@onready var enemies_container = $Enemies  # Make sure this node exists under SpawnPoint
@export var grappling_demo_path: NodePath  # Drag GrapplingDemo into this in the Inspector
@export var enemy_scene: PackedScene       # Drag your Enemy.tscn here
@export var min_enemies := 3
@export var max_enemies := 10

func _ready():
	print("SpawnPoint ready, connecting area signal.")
	# Spawn enemies
	_spawn_random_enemies()
	area.connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	print("Entered body:", body.name)
	if body.name == "PlayerBody":  # Or body.is_in_group("player")
		print("Player arrived at spawn point.")
		if has_node(grappling_demo_path):
			var grappling_demo = get_node(grappling_demo_path)
			if grappling_demo:
				grappling_demo.spawn_enemy()  # Call the function in GrapplingDemo
				print("GrapplingDemo found!")
		else:
			push_error("GrapplingDemo not found.")

		# Remove this spawn point
		queue_free()

func _spawn_random_enemies():
	if not enemy_scene:
		push_error("No enemy scene assigned.")
		return

	var num_enemies = randi_range(min_enemies, max_enemies)
	var sphere_shape = collision.shape as SphereShape3D
	var scale_factor = area.scale  # Get the scale of the sphere nod
	var radius = sphere_shape.radius* scale_factor.x
	# Print the radius to the output console
	print("The radius of the sphere is: ", radius)
	

	for i in num_enemies:
		var enemy = enemy_scene.instantiate()

		# Generate a random point within a circle (XZ plane), then place on ground (Y axis)
		var angle = randf() * TAU
		var distance = sqrt(randf()) * radius  # sqrt() gives uniform distribution in circle

		var offset = Vector3(
			cos(angle) * distance,
			0.0,
			sin(angle) * distance
		)

		var global_position = area.global_transform.origin + offset
		enemy.global_position = global_position
		enemies_container.add_child(enemy)
