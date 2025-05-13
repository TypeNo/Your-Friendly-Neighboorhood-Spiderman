extends RigidBody3D

@export var web_scene: PackedScene
@export var vertical_offset: float = 1.0  # Adjust this in inspector!
@export var horizontal_offset: float = 1.0  # Adjust this in inspector!
var has_hit = false

func _ready():
	# Create and assign white material
	angular_damp = 10.0
	# REQUIRED: Enable collision monitoring
	contact_monitor = true
	max_contacts_reported = 1
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	print("web entering enemy body")
	if has_hit: return
	has_hit = true
	
	print("Projectile hit: ", body.name)  # Debug
	
	if body.is_in_group("enemy"):
		print("Enemy hit!")
		body.immobilize()
		spawn_web(body)
	
	queue_free()

func shoot(force: Vector3):
	# Clear rotation and apply force
	rotation = Vector3.BACK
	apply_impulse(force)

func _on_timer_timeout():
	queue_free()
	

func spawn_web(enemy):
	if !web_scene or !is_instance_valid(enemy):
		return

	var web = web_scene.instantiate()
	
	# Attach web directly to enemy
	enemy.add_child(web)
	
	# Center web on enemy position
	web.global_position = enemy.global_position + Vector3(0, vertical_offset, horizontal_offset)
	web.global_rotation = Vector3.ZERO  # Optional: Align with world
	
	print("Web spawned on enemy at: ", web.global_position)
	
