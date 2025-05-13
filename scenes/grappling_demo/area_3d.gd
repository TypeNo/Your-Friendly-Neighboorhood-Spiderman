extends Area3D

@export var min_damage_velocity := 3.0
@export var max_damage_velocity := 10.0
@export var base_damage := 10.0
@export var max_damage := 50.0
@export var controller_node: XRController3D  # assign this in the editor to the correct controller

var controller_velocity := Vector3.ZERO


func _physics_process(delta):
	if controller_node:
		controller_velocity = controller_node.velocity

func _on_body_entered(body):
	print("we are in main body entered")
	if body.is_in_group("enemy"):
		var speed = controller_velocity.length()
		var damage = clampf(
			remap(speed, min_damage_velocity, max_damage_velocity, base_damage, max_damage),
			base_damage,
			max_damage
		)
		
		
		
		body.take_damage(damage)
		# Calculate push force (velocity-based)
		var push_direction = (body.global_position - global_position).normalized()
		var velocity_bonus = clamp(speed / max_damage_velocity, 0.5, 2.0)
		
		# Apply force
		if body is RigidBody3D:
			body.apply_central_impulse(push_direction * damage * velocity_bonus)
			print("Punch velocity: ", speed, " | Damage: ", damage)

		DebugDraw3D.draw_line(
		global_position,
		global_position + controller_velocity,
		Color.RED,
		0.1
)
