@tool
extends XRToolsMovementGrapple

## Swinging button (triggers swinging movement).  Be sure this button does not
## conflict with other functions.
@export var swing_button_action : String = "grip_click"

var _swing_button := false

# Set the grappling state and fire any signals
func _set_swinging(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update the is_active flag
	is_active = active;

	# Report transition
	if is_active:
		emit_signal("swing_started")
	else:
		emit_signal("swing_finished")

func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	if disabled or !enabled or !_controller.get_is_active():
		_set_swinging(false)
		return

	var old_swing_button := _swing_button
	_swing_button = _controller.is_button_pressed(swing_button_action)

	if is_active and !_swing_button:
		_set_swinging(false)
	elif _swing_button and !old_swing_button and _is_raycast_valid():
		hook_object = _grapple_raycast.get_collider()
		hook_point = _grapple_raycast.get_collision_point()
		hook_local = hook_object.global_transform.affine_inverse() * hook_point
		_set_swinging(true)

	if !is_active:
		return

	# Recalculate the world hook point
	hook_point = hook_object.global_transform * hook_local

	# Vector from player to hook
	var player_pos = _controller.global_transform.origin
	var hook_vector = hook_point - player_pos
	var hook_length = hook_vector.length()

	# Normalize direction
	var hook_direction = hook_vector / hook_length

	# Apply gravity
	player_body.velocity += player_body.gravity * delta

	# === Begin Swing Mechanics ===

	# Get velocity component toward the rope direction (tension direction)
	var v_along_rope = player_body.velocity.project(hook_direction)
	var v_perpendicular = player_body.velocity - v_along_rope

	# Maintain rope length by correcting any velocity pulling the player *away* from the hook
	if v_along_rope.dot(hook_direction) > 0:
		# Remove the away component — simulate tension in rope
		player_body.velocity = v_perpendicular

	# Optional: apply a small centripetal force inward to keep swing tight
	var tension_strength = 2.0  # tweak this value
	player_body.velocity += -hook_direction * tension_strength * delta

	# Optional: slight damping
	player_body.velocity *= (1.0 - friction * delta)

	# === Move player ===
	player_body.velocity = player_body.move_player(player_body.velocity)
