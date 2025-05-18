extends XROrigin3D

<<<<<<< HEAD
var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")
=======
func take_damage():
	print("OUCH! Took damage!")
>>>>>>> 083fc4ef6cf4b7cd72e53e4205f86510c2d05d14
