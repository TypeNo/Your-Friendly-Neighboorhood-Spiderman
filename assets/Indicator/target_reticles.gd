extends Node3D

var camera

@onready var target_reticle = $TargetReticles
@onready var offscreen_reticle = $OffscreenReticles

var reticle_offset = Vector2(32,32)

func _ready():
	camera = get_viewport().get_camera_3d()

	if camera:
		print("Active Camera3D Node Name:", camera.name)
		print("Full Path:", camera.get_path())
	else:
		print("No active Camera3D found in the viewport.")

func _process(delta):
	if camera.is_position_in_frustum(global_position):
		target_reticle.show()
		offscreen_reticle.hide()
		var reticle_position = camera.unproject_position(global_position)
		target_reticle.set_global_position(reticle_position-reticle_offset)
