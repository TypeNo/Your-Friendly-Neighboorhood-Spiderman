extends Node3D

func _ready():
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
