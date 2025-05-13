extends Node3D

func _ready():
	var parent_transform = $Parent.global_transform
	global_transform = parent_transform
