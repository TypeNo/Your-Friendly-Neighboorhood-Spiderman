#extends RigidBody3D
#
#@export var speed := 5.0
#@export var attack_range := 1.5
#@export var rotation_speed := 8.0  # How fast to rotate towards player
#
#var player
#var can_attack := true
#
#func _ready():
	## Freeze ALL rotation axes
	#freeze = true
	## Zero friction physics material
	#physics_material_override = PhysicsMaterial.new()
	#physics_material_override.friction = 0.0
#
#func _physics_process(delta):
	#if !is_instance_valid(player): return
	#
	## Calculate direction and distance
	#var to_player = player.global_position - global_position
	#var distance = to_player.length()
	#var direction = to_player.normalized()
	#
	## Rotate to face player smoothly (no physics rotation)
	#var target_rotation = Basis.looking_at(direction, Vector3.UP)
	#transform.basis = transform.basis.slerp(target_rotation, rotation_speed * delta)
	#
	## Move forward in the direction it's FACING (not direct towards player)
	#var move_direction = -transform.basis.z  # Forward vector
	#if distance > attack_range:
		#apply_central_force(move_direction * speed * 50 * delta)
	#
	## Attack logic
	#if distance <= attack_range:
		#if can_attack: attack()
		#linear_velocity *= 0.9  # Slow down
#
#func attack():
	#print("Attacking!")
	#if player.has_method("take_damage"):
		#player.take_damage(10)
	#can_attack = false
	#await get_tree().create_timer(1.0).timeout
	#can_attack = true
