extends XRController3D

@export var projectile_scene: PackedScene
@export var shoot_force: float = 15.0
@export var spawn_offset: Vector3 = Vector3(0, 0, -0.2)  # Move spawn in front of controller

# Cooldown system
var can_shoot = true
var fire_rate = 0.2  # Seconds between shots
var velocity := Vector3.ZERO
var _last_position := Vector3.ZERO

func _ready():
	_last_position = global_position

func _process(delta):
	
	velocity = (global_position - _last_position) / delta
	_last_position = global_position
	
	if is_button_pressed("by_button") and can_shoot:
		# Fire rate limiter
		can_shoot = false
		get_tree().create_timer(fire_rate).connect("timeout", func(): can_shoot = true)
		
		# Spawn projectile
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		
		# Calculate spawn position and rotation
		var spawn_point = global_transform.translated_local(spawn_offset)
		projectile.global_transform = spawn_point
		
		# Get proper forward direction (negative Z-axis of controller)
		var direction = -global_transform.basis.z.normalized()
		projectile.shoot(direction * shoot_force)
