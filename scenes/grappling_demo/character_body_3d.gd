extends CharacterBody3D

@export var anim_player: AnimationPlayer
@export var speed := 4.0
@export var attack_range := 2.0
@export var attack_cooldown := 1.0
@export var follow_delay := 1  # seconds to wait before chasing again
@export var damage := 5.0

var health := 100.0
var is_immobilized = false
var can_attack := true
var attacking := false
var animation_locked := false
var attack_animations = ["enemy/Attack", "enemy/Attack 2", "enemy/Attack 3"]
var hurt_animations = ["enemy/hitted", "enemy/hitted 2"]

var player
var prev_in_range := false
var can_follow := true
var follow_timer: Timer

func _ready():
	# find/player
	randomize()
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	else:
		push_error("Player not found!")
		set_physics_process(false)
		return

	# setup follow‐delay timer
	follow_timer = Timer.new()
	follow_timer.wait_time = follow_delay
	follow_timer.one_shot = true
	follow_timer.timeout.connect(_on_follow_delay_timeout)
	add_child(follow_timer)

func _physics_process(delta):
	if is_immobilized or animation_locked or !is_instance_valid(player):
		# if hurt/dead or immobilized, do nothing
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()
	var in_range = distance <= attack_range

	# detect range transitions to kick off follow‐delay
	if in_range and not prev_in_range:
		# just entered attack range → stop follow‐delay, allow follow on exit
		can_follow = true
		if follow_timer.is_stopped() == false:
			follow_timer.stop()
	elif not in_range and prev_in_range:
		# just exited attack range → block follow until timer fires
		can_follow = false
		follow_timer.start()
	prev_in_range = in_range

	# rotate to face player
	look_at(player.global_position, Vector3.UP)
	rotate_y(deg_to_rad(180))  # only if your mesh is +Z-forward

	# movement + attack
	if in_range:
		velocity = Vector3.ZERO
		if not attacking and can_attack:
			attack_loop()
	elif can_follow:
		velocity = direction * speed
	else:
		# still on follow‐delay
		velocity = Vector3.ZERO

	move_and_slide()
	_update_idle_run_animation(distance)

func _on_follow_delay_timeout():
	can_follow = true

func _update_idle_run_animation(distance):
	# if neither attacking nor locked by hurt/death, play idle/run
	if attacking or animation_locked:
		return
	if distance > attack_range:
		_play_anim("enemy/Running")
	else:
		_play_anim("enemy/enemyidle")

func attack_loop():
	attacking = true
	play_random_attack_animation()
	await anim_player.animation_finished
	# apply damage at animation end
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(damage)
	# cooldown
	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
	attacking = false

func take_damage(amount: float):
	if animation_locked:
		return
	health -= amount
	print(name, " health: ", health)
	animation_locked = true
	play_random_hurt_animation()
	await anim_player.animation_finished
	animation_locked = false
	if health <= 0:
		die()

func die():
	animation_locked = true
	_play_anim("enemy/Death", 0.2)
	await anim_player.animation_finished
	queue_free()

func _play_anim(name: String, blend: float = 0.1):
	if anim_player.current_animation == name:
		return
	anim_player.play(name, blend)
func immobilize():
	if is_immobilized:
		return
	is_immobilized = true
	velocity = Vector3.ZERO  # stop movement immediately
	if follow_timer and follow_timer.is_stopped() == false:
		follow_timer.stop()  # prevent chasing during immobilization

	# Timer to remove immobilization
	var web_timer = Timer.new()
	web_timer.wait_time = 5.0
	web_timer.one_shot = true
	web_timer.timeout.connect(_on_web_timeout.bind(web_timer))
	add_child(web_timer)
	web_timer.start()

func _on_web_timeout(timer):
	timer.queue_free()
	is_immobilized = false
	can_follow = true  # optionally re-enable following after immobilization

	# Clean up any visual web effects
	for child in get_children():
		if child.is_in_group("web"):
			child.queue_free()
			
			
func play_random_attack_animation():
	if anim_player:
		var anim_attack = attack_animations[randi() % attack_animations.size()]
		anim_player.play(anim_attack, 0.3)
		
func play_random_hurt_animation():
	if anim_player:
		var anim_hit = hurt_animations[randi() % hurt_animations.size()]
		anim_player.play(anim_hit, 0.3)
