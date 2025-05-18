extends Area3D


# On the HitboxArea (Area3D) node
func _ready():
	$Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "PlayerBody":
		# Remove or hide the enemy
		queue_free() # or self.visible = false
