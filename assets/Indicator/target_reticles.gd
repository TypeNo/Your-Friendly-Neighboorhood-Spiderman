extends Node3D

var camera

@onready var target_reticle = $TargetReticles
@onready var offscreen_reticle = $OffscreenReticles
@onready var mesh_instance = $Skeleton3D/Ch44  # Make sure this is correct

var target_height = 0.0
var model_origin = Vector3.ZERO
var model_center = Vector3.ZERO
var reticle_offset = Vector2.ZERO
var time = 0.0  # Track time for animations
var initialized = false  # Flag to ensure we initialize only once

func _ready():
	#_enemy_init_anim()
	
	camera = get_viewport().get_camera_3d()

	if camera:
		print("Active Camera3D Node Name:", camera.name)
	else:
		push_error("No active Camera3D found in the viewport.")
		return

	if mesh_instance and mesh_instance.has_method("get_aabb"):
		var aabb = mesh_instance.get_aabb()
		target_height = aabb.size.y
		model_origin = aabb.position + (aabb.size / 2.0)
		model_origin.y=0
		#model_origin = mesh_instance.global_transform.origin
		model_center = model_origin + mesh_instance.global_transform.basis.y * target_height
		model_center.y -= target_height/4

		print("Debug Info from _ready():")
		print("- half_height:", target_height)
		print("- model_center:", model_origin)
		print("- model_top:", model_center)
	else:
		push_error("Mesh instance not found or doesn't support get_aabb().")

	if target_reticle.material is ShaderMaterial:
	# Check if the shader parameter exists and is initialized
		if target_reticle.material.get_shader_parameter("rotation_angle") == null:
			target_reticle.material.set_shader_parameter("rotation_angle", 0.0)  # Set initial value
			initialized = true  # Mark as initialized
		
		# Debug info to see if the parameter exists and its value
		print("Initial rotation_angle:", target_reticle.material.get_shader_parameter("rotation_angle"))

func _process(delta):
	if not camera:
		return

	time += delta  # Increment time for animations

	if camera.is_position_in_frustum(global_position):
		target_reticle.show()
		offscreen_reticle.hide()

		var world_target_pos = global_position + model_center

		# Calculate distance between camera and model center
		var distance = camera.global_transform.origin.distance_to(world_target_pos)

		# Scale factor: tweak base and divisor as needed
		var base_size = 0.039  # Adjust to match your desired on-screen size
		var scale_factor = base_size / distance  # Inverse relationship

		# Optionally clamp to prevent too small or too large reticle
		scale_factor = clamp(scale_factor, 0, base_size)

		# Add pulsing effect
		var pulse_factor = 1.0 + 0.2 * sin(time * 2.0)  # Adjust 0.2 for pulse amplitude, 2.0 for speed
		target_reticle.scale = Vector2.ONE * scale_factor * pulse_factor

		# Set pivot to center of TextureRect (update after scale)
		#target_reticle.pivot_offset = target_reticle.size* target_reticle.scale / 2

		# Add spinning effect for 2D node
		var spin_speed = 90.0  # Degrees per second
		#target_reticle.rotation_degrees = time * spin_speed

		# Update the shader's rotation angle (in degrees)
		if target_reticle.material is ShaderMaterial:
			# Ensure parameter exists and is initialized before updating it
			if not initialized:
				if target_reticle.material.get_shader_parameter("rotation_angle") == null:
					target_reticle.material.set_shader_parameter("rotation_angle", 0.0)  # Set initial value
					initialized = true  # Mark as initialized
					print("rotation_angle initialized to 0.0")

			# Now, safely retrieve and update the parameter
			var current_angle = target_reticle.material.get_shader_parameter("rotation_angle")
			print("Current rotation_angle before update:", current_angle)  # Debug current angle
			target_reticle.material.set_shader_parameter("rotation_angle", current_angle + spin_speed * delta)

			# Debug updated value
			print("Updated rotation_angle:", target_reticle.material.get_shader_parameter("rotation_angle"))

		reticle_offset = target_reticle.size / 2 * target_reticle.scale
		
		var screen_pos = camera.unproject_position(world_target_pos)
		target_reticle.set_global_position(screen_pos - reticle_offset)

		# Debug output
		print("Debug Info from _process():")
		print("- distance to camera:", distance)
		print("- scale_factor:", scale_factor)
		print("- pulse_factor:", pulse_factor)
		print("- screen_pos:", screen_pos)
		print("- target_pos:", target_reticle.global_position)
		print("- reticle_offset:", reticle_offset)
		print("- pivot_offset:", target_reticle.pivot_offset)
	else:
		target_reticle.hide()
		offscreen_reticle.show()
		
func _enemy_init_anim():
	var anim_player = $AnimationPlayer  # Reference to the AnimationPlayer node
	var anim = anim_player.get_animation("Idle")
	if anim:
		# Set the loop mode (PingPong or Loop)
		anim.loop_mode = Animation.LOOP_PINGPONG
		anim.loop = true  # Correct way to enable looping

		# Play the animation using the AnimationPlayer
		anim_player.play("Idle")  # Use play() from AnimationPlayer
	else:
		push_error("Animation 'Idle' not found.")
	
