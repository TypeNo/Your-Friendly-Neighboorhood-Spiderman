extends SkeletonIK3D

@onready var skeleton_ik_Head := $"."
@onready var skeleton_ik_lHand := $"../LeftHand"
@onready var skeleton_ik_rHand := $"../RightHand"

func _ready():
	skeleton_ik_Head.start()
	skeleton_ik_lHand.start()
	skeleton_ik_rHand.start()
