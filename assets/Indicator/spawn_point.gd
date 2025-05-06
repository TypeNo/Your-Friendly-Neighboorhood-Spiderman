extends Node3D

@onready var area = $Area3D
@export var grappling_demo_path: NodePath  # Drag GrapplingDemo into this in the Inspector

func _ready():
	print("SpawnPoint ready, connecting area signal.")
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
