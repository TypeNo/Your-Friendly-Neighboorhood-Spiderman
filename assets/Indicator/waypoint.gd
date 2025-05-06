extends Control


# Some margin to keep the marker away from the screen's corners.
const MARGIN = 50

# The waypoint's text.
@export var text = "Waypoint": set = set_text

# If `true`, the waypoint sticks to the viewport's edges when moving off-screen.
@export var sticky = true

var xr_camera: XRCamera3D
@onready var parent = get_parent()
@onready var label = $VBoxContainer/Label
@onready var marker = $Marker


func _ready() -> void:
	self.text = text

	if not parent is Node3D:
		push_error("The waypoint's parent node must inherit from Node3D.")
	
	if get_tree().get_root().has_node("GrapplingDemo/XROrigin3D/XRCamera3D"):
		xr_camera = get_node("/root/GrapplingDemo/XROrigin3D/XRCamera3D")
	else:
		push_error("XRCamera3D not found!")

	anchor_left = 0
	anchor_top = 0
	anchor_right = 0
	anchor_bottom = 0
	# Ensure the control is anchored to the top-left
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	# Set position to the top-left corner
	position = Vector2.ZERO
	# Set pivot offset to top-left
	pivot_offset = Vector2.ZERO


var last_state := {}

func _process(_delta):
	var parent_translation = parent.get_parent().global_transform.origin
	parent_translation.y+=1
	var xr_camera_transform = xr_camera.global_transform
	var xr_camera_translation = xr_camera_transform.origin

	var is_behind = xr_camera_transform.basis.z.dot(parent_translation - xr_camera_translation) > 0
	var distance = xr_camera_translation.distance_to(parent_translation)
	var alpha = clamp(remap(distance, 0, 5, 0, 1), 0, 1)
	modulate.a = alpha

	var unprojected_position = xr_camera.unproject_position(parent_translation)
	var ori_unprojected_position = unprojected_position

	# We'll set position later; for now, prepare the values
	var computed_position = position # Will update after sticky logic below

	# Handle sticky logic
	var viewport_base_size = (
			get_viewport().get_visible_rect().size if get_viewport().get_visible_rect().size > Vector2(0, 0)
			else get_viewport().size
	)
	if sticky:
		if is_behind:
			if unprojected_position.x < viewport_base_size.x / 2:
				unprojected_position.x = viewport_base_size.x - MARGIN
			else:
				unprojected_position.x = MARGIN

		if is_behind or unprojected_position.x < MARGIN or unprojected_position.x > viewport_base_size.x - MARGIN:
			var look = xr_camera_transform.looking_at(parent_translation, Vector3.UP)
			var diff = angle_diff(look.basis.get_euler().x, xr_camera_transform.basis.get_euler().x)
			unprojected_position.y = viewport_base_size.y * (0.5 + (diff / deg_to_rad(xr_camera.fov)))

	else:
		computed_position = unprojected_position
		position = computed_position + get_viewport().get_visible_rect().size
		visible = not is_behind
		return

	var screen_position = unprojected_position + get_viewport().get_visible_rect().position
	computed_position = Vector2(
		clamp(screen_position.x, MARGIN, viewport_base_size.x - MARGIN),
		clamp(screen_position.y, MARGIN, viewport_base_size.y - MARGIN)
	)

	# Apply final position
	position = computed_position

	label.visible = true
	rotation = 0
	# Used to display a diagonal arrow when the waypoint is displayed in
	# one of the screen corners.
	var overflow = 0

	if position.x <= MARGIN:
		# Left overflow.
		overflow = -45
		label.visible = false
		rotation = 90
	elif position.x >= viewport_base_size.x - MARGIN:
		# Right overflow.
		overflow = 45
		label.visible = false
		rotation = 270

	if position.y <= MARGIN:
		# Top overflow.
		label.visible = false
		rotation = 180 + overflow
	elif position.y >= viewport_base_size.y - MARGIN:
		# Bottom overflow.
		label.visible = false
		rotation = -overflow

	var my_viewport = get_viewport()
	var viewport_message = ""
	if my_viewport == get_tree().root:
		viewport_message = "This is the root (main) viewport."
	else:
		viewport_message = "This is a different (likely sub) viewport."

	var current_state = {
		"parent_position": parent_translation,
		"is_behind": is_behind,
		"distance": distance,
		"alpha": alpha,
		"ori_unprojected_position" : ori_unprojected_position,
		"unprojected_position": unprojected_position,
		"computed_position": computed_position,
		"camera_position" : xr_camera_translation,
		"viewport_base_size.x" : viewport_base_size.x,
		"viewport_base_size.y" : viewport_base_size.y,
		"Viewport node" : my_viewport,
		"Viewport path" : my_viewport.get_path(),
		"Viewport position" : my_viewport.get_visible_rect().position,
		"Viewport message": viewport_message
	}


	if current_state != last_state:
		#print("=== Waypoint Debug ===")
		#for key in current_state.keys():
			#print(key + ": ", current_state[key])
		last_state = current_state

func set_text(p_text):
	text = p_text

	# The label's text can only be set once the node is ready.
	if is_inside_tree():
		label.text = p_text


static func angle_diff(from, to):
	var diff = fmod(to - from, TAU)
	return fmod(2.0 * diff, TAU) - diff
