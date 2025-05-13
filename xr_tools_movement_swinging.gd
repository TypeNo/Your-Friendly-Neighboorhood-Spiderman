@tool
extends XRToolsMovementGrapple

## Swinging button (triggers swinging movement).  Be sure this button does not
## conflict with other functions.
@export var swing_button_action : String = "by_button"

# Get line creation nodes
#@onready var swing_line_helper : Node3D = $LineHelper
#@onready var swing_line : CSGCylinder3D = $LineHelper/Line

# Get Controller node - consider way to universalize this if user wanted to
# attach this to a gun instead of player's hand.  Could consider variable to
# select controller instead.
#@onready var swing_controleeeler := XRHelpers.get_xr_controller(self)

# Get Raycast node
#@onready var swing_grapple_raycast : RayCast3D = $Grapple_RayCast

# Get Grapple Target Node
#@onready var swing_grapple_target : Node3D = $Grapple_Target

# Function run when node is added to scene
func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Skip if running in the editor
	if Engine.is_editor_hint():
		return

	# Ensure grapple length is valid
	var min_hook_length := 1.5 * XRServer.world_scale
	if grapple_length < min_hook_length:
		grapple_length = min_hook_length

	# Set ray-cast
	_grapple_raycast.target_position = Vector3(0, 0, -grapple_length) * XRServer.world_scale
	_grapple_raycast.collision_mask = grapple_collision_mask

	# Deal with line
	_line.radius = rope_width
	_line.hide()

# Update the grappling line and target
func _physics_process(_delta : float):
	# Skip if running in the editor
	if Engine.is_editor_hint():
		return

	# If pointing grappler at target then show the target
	if enabled and not is_active and _is_raycast_valid():
		_grapple_target.global_transform.origin = _grapple_raycast.get_collision_point()
		_grapple_target.global_transform = _grapple_target.global_transform.orthonormalized()
		_grapple_target.visible = true
	else:
		_grapple_target.visible = false

	# If actively grappling then update and show the grappling line
	if is_active:
		var line_length := (hook_point - _controller.global_transform.origin).length()
		_line_helper.look_at(hook_point, Vector3.UP)
		_line.height = line_length
		_line.position.z = line_length / -2
		_line.visible = true
	else:
		_line.visible = false

# Called every physics frame
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

		# Apply impulse/momentum toward hook point
		var player_pos = _controller.global_transform.origin
		var hook_vector = hook_point - player_pos
		max_rope_length = 0.5 * hook_vector.length()
		var hook_dir = hook_vector.normalized()

		const GRAPPLE_IMPULSE_STRENGTH := 8.0
		player_body.velocity += hook_dir * GRAPPLE_IMPULSE_STRENGTH
		#player_body.velocity += Vector3.UP * 4.0  # optional upward boost for swing energy

	if !is_active:
		return

	# Validate hook
	if !is_instance_valid(hook_object):
		_set_swinging(false)
		return

	# Recalculate hook point in world space
	hook_point = hook_object.global_transform * hook_local

	# Player-to-hook vector
	var player_pos = _controller.global_transform.origin
	var hook_vector = hook_point - player_pos
	var hook_length = hook_vector.length()

	# Normalize direction
	var hook_dir = hook_vector / hook_length

	# Apply gravity
	player_body.velocity += player_body.gravity * delta

	# Apply rope tension only when overstretched
	const SLACK_MARGIN := 0.5  # in meters
	var overstretch = hook_length - max_rope_length + SLACK_MARGIN
	if overstretch > 0.0:
		var tension_force = hook_dir * overstretch * SPRING_CONSTANT
		player_body.velocity += tension_force * delta

	
	# --- Core circular constraint logic starts here ---

	# Enforce circular arc by clamping position and velocity

	if hook_length < max_rope_length:
		# Constrain position to rope length
		#var corrected_pos = hook_point + hook_dir * MAX_ROPE_LENGTH
		#_controller.global_transform.origin = corrected_pos

		# Remove radial velocity (only tangential remains)
		var v_radial = player_body.velocity.project(hook_dir)
		var v_perpendicular = player_body.velocity - v_radial
		player_body.velocity -= v_radial


		if v_radial.dot(hook_dir) > 0:
			player_body.velocity = v_perpendicular

		# Clamp player to circular path (optional correction)
		#var corrected_pos = hook_point - hook_dir * MAX_ROPE_LENGTH
		#_controller.global_transform.origin = corrected_pos

		# Correct velocity to be purely tangential
		#var velocity_dir = player_body.velocity.normalized()
		#var tangent = velocity_dir.cross(hook_dir).cross(hook_dir).normalized()
		#player_body.velocity = tangent * player_body.velocity.length()

	# Optional damping (comment out if you want maximum swing energy)
	#const TENSION_DAMPING := 2.0
	#player_body.velocity *= (1.0 - TENSION_DAMPING * delta)

	if (player_body.velocity.dot(Vector3.UP)) > 0.1 :
		player_body.velocity += hook_dir * 0.1  # optional swing booster

	if (hook_vector.dot(Vector3.UP)) > 0.1 :
		player_body.velocity += hook_dir * 0.1  # optional swing booster

	
	#if player_body.velocity.dot(Vector3.FORWARD) > 0.9 and hook_dir.dot(Vector3.BACK) > 0.9:
	#	player_body.velocity += hook_dir * 2.0  # optional swing booster

	# Move the player
	player_body.velocity = player_body.move_player(player_body.velocity)

# Called when the grapple collision mask has been modified
func _set_grapple_collision_mask(new_value: int) -> void:
	grapple_collision_mask = new_value
	if is_inside_tree() and _grapple_raycast:
		_grapple_raycast.collision_mask = new_value

# State transition
func _set_swinging(active: bool) -> void:
	if active == is_active:
		return

	is_active = active
	if is_active:
		emit_signal("swing_started")
		print("swing_started")
	else:
		emit_signal("swing_finished")
		print("swing_finished")

# Test if the raycast is striking a valid target
func _is_raycast_valid() -> bool:
	# Test if the raycast hit a collider
	var target = _grapple_raycast.get_collider()
	if not is_instance_valid(target):
		return false

	# Check collider layer
	return true if target.collision_layer & grapple_enable_mask else false

# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Check the controller node
	if !XRHelpers.get_xr_controller(self):
		warnings.append("This node must be within a branch of an XRController3D node")

	# Return warnings
	return warnings
