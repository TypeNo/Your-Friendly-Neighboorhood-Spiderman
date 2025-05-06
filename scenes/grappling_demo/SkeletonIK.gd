extends SkeletonIK3D

@onready var skeleton_ik_Head := $"."
@onready var skeleton_ik_lArm := $"../LeftHand"
@onready var skeleton_ik_rArm := $"../RightHand"

func _ready():
	skeleton_ik_Head.start()
	skeleton_ik_lArm.start()
	skeleton_ik_rArm.start()
