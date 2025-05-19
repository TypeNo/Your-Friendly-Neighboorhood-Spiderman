@tool
class_name XRToolsMovementGrapple
extends XRToolsMovementProvider


## XR Tools Movement Provider for Grapple Movement
##
## This script provide simple grapple based movement - "bat hook" style
## where the player flings a rope to the target and swings on it.
## This script works with the [XRToolsPlayerBody] attached to the players
## [XROrigin3D].


## Signal emitted when grapple starts
signal grapple_started()

## Signal emitted when grapple finishes
signal grapple_finished()


## Grapple state
enum GrappleState {
	IDLE,			## Grapple is idle
	FIRED,			## Grapple is fired
	WINCHING,		## Grapple is winching
}


# Default grapple collision mask of 1-5 (world)
const DEFAULT_COLLISION_MASK := 0b0000_0000_0000_0000_0000_0000_0001_1111

# Default grapple enable mask of 5:grapple-target
const DEFAULT_ENABLE_MASK := 0b0000_0000_0000_0000_0000_0000_0001_0000


## Movement provider order
@export var order : int = 20

## Grapple length - use to adjust maximum distance for possible grapple hooking.
@export var grapple_length : float = 20.0

## Grapple collision mask
@export_flags_3d_physics var grapple_collision_mask : int = DEFAULT_COLLISION_MASK:
	set = _set_grapple_collision_mask

## Grapple enable mask
@export_flags_3d_physics var grapple_enable_mask : int = DEFAULT_ENABLE_MASK

## Impulse speed applied to the player on first grapple
@export var impulse_speed : float = 10.0

## Winch speed applied to the player while the grapple is held
@export var winch_speed : float = 2.0

## Probably need to add export variables for line size, maybe line material at
## some point so dev does not need to make children editable to do this.
## For now, right click on grapple node and make children editable to edit these
## facets.
@export var rope_width : float = 0.02

## Air friction while grappling
@export var friction : float = 0.1

## Grapple button (triggers grappling movement).  Be sure this button does not
## conflict with other functions.
@export var grapple_button_action : String = "trigger_click"
@export var swing_button_action : String = "grip_click"

# Hook related variables
var hook_object : Node3D = null
var hook_local := Vector3(0,0,0)
var hook_point := Vector3(0,0,0)

# Grapple button state
var _grapple_button := false

# Get line creation nodes
@onready var _line_helper : Node3D = $LineHelper
@onready var _line : CSGCylinder3D = $LineHelper/Line

# Get Controller node - consider way to universalize this if user wanted to
# attach this to a gun instead of player's hand.  Could consider variable to
# select controller instead.
@onready var _controller := XRHelpers.get_xr_controller(self)

# Get Raycast node
@onready var _grapple_raycast : RayCast3D = $Grapple_RayCast

# Get Grapple Target Node
@onready var _grapple_target : Node3D = $Grapple_Target


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementGrapple" or super(name)


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


var _swing_button := false

const MAX_ROPE_LENGTH :=10.0  # Max distance before rope snaps
const SPRING_CONSTANT := 2.5   # Strength of swing tightening
const TENSION_DAMPING := 0.2   # Swing damping factor
const MAX_TENSION_FORCE:=200.0
var max_rope_length

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



# Called every physics frame
func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	if disabled or !enabled or !_controller.get_is_active():
		_set_grappling(false)
		_set_swinging(false)
		return

	# Detect button states
	var old_button := _grapple_button
	var impulse_pressed := _controller.is_button_pressed(grapple_button_action)
	var swing_pressed := _controller.is_button_pressed(swing_button_action)

	# Set mode based on current button press
	var grapple_mode := ""
	if impulse_pressed:
		grapple_mode = "impulse"
	elif swing_pressed:
		grapple_mode = "swing"

	# Determine if any button is pressed
	var button_pressed := impulse_pressed or swing_pressed
	_grapple_button = button_pressed

	# Trigger grappling/swinging
	var do_impulse := false
	if is_active and !button_pressed:
		_set_grappling(false)
		_set_swinging(false)
	elif button_pressed and !old_button and _is_raycast_valid():
		hook_object = _grapple_raycast.get_collider()
		hook_point = _grapple_raycast.get_collision_point()
		hook_local = hook_object.global_transform.affine_inverse() * hook_point

		if grapple_mode == "impulse":
			do_impulse = true
			_set_grappling(true)
		elif grapple_mode == "swing":
			_set_swinging(true)
			var player_pos = _controller.global_transform.origin
			var hook_vector = hook_point - player_pos
			max_rope_length = 0.4 * hook_vector.length()
			var hook_dir = hook_vector.normalized()
			const GRAPPLE_IMPULSE_STRENGTH := 1.0
			player_body.velocity += hook_dir * GRAPPLE_IMPULSE_STRENGTH

	# Exit if not active
	if !is_active:
		return

	# Validate hook
	if !is_instance_valid(hook_object):
		_set_grappling(false)
		_set_swinging(false)
		return

	# Recalculate world-space hook point
	hook_point = hook_object.global_transform * hook_local
	var player_pos = _controller.global_transform.origin
	var hook_vector = hook_point - player_pos
	var hook_length = hook_vector.length()
	var hook_dir = hook_vector / hook_length

	# Apply gravity
	player_body.velocity += player_body.gravity * delta

	if grapple_mode == "impulse":
		var speed := impulse_speed if do_impulse else winch_speed
		if hook_length < 1.0:
			speed = 0.0
		var vdot = player_body.velocity.dot(hook_dir)
		if vdot < speed:
			player_body.velocity += hook_dir * (speed - vdot)
		player_body.velocity *= 1.0 - friction * delta

	elif grapple_mode == "swing":
		const SLACK_MARGIN := 0.5
		var overstretch = hook_length - MAX_ROPE_LENGTH + SLACK_MARGIN
		if overstretch > 0.0:
			var tension_force = hook_dir * overstretch * SPRING_CONSTANT
			if tension_force.length() > MAX_TENSION_FORCE:
				tension_force = tension_force.normalized() * MAX_TENSION_FORCE
			player_body.velocity += tension_force * delta

		if hook_length < MAX_ROPE_LENGTH:
			var v_radial = player_body.velocity.project(hook_dir)
			var v_perpendicular = player_body.velocity - v_radial
			if v_radial.dot(hook_dir) > 0:
				player_body.velocity = v_perpendicular

		# Optional swing boosters
		if player_body.velocity.dot(Vector3.UP) > 0.1:
			player_body.velocity += hook_dir * 0.1
		if hook_vector.dot(Vector3.UP) > 0.1:
			player_body.velocity += hook_dir * 0.1

		# Optional damping (comment out if you want maximum swing energy)
		const TENSION_DAMPING := 4.0
		player_body.velocity *= (1.0 - TENSION_DAMPING * delta)
		#player_body.velocity *= 1.0 - friction * delta

	# Final movement
	player_body.velocity = player_body.move_player(player_body.velocity)




# Called when the grapple collision mask has been modified
func _set_grapple_collision_mask(new_value: int) -> void:
	grapple_collision_mask = new_value
	if is_inside_tree() and _grapple_raycast:
		_grapple_raycast.collision_mask = new_value


# Set the grappling state and fire any signals
func _set_grappling(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update the is_active flag
	is_active = active;

	# Report transition
	if is_active:
		emit_signal("grapple_started")
		print("grapple_started")
	else:
		emit_signal("grapple_finished")
		print("grapple_finished")



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
