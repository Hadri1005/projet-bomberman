extends CharacterBody3D

const TILE_SIZE = 1.0
const KICK_SPEED = 6.0
const FUSE_TIME = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const EXPLOSION_SCENE = preload("res://explosion/explosion.tscn")
var is_moving = false
var move_direction = Vector3.ZERO
var blink_tween: Tween = null

# Joueurs qui ignorent encore la collision avec cette bombe
var ignored_players: Array[Node3D] = []

func _ready():
	$Timer.wait_time = FUSE_TIME
	$Timer.one_shot = true
	$Timer.start()
	$Timer.timeout.connect(_on_timer_timeout)
	var blink_timer = Timer.new()
	add_child(blink_timer)
	blink_timer.wait_time = FUSE_TIME - 1.5
	blink_timer.one_shot = true
	blink_timer.timeout.connect(start_blinking)
	blink_timer.start()


func _physics_process(delta):
	# Retire l'exception seulement quand le joueur est entierement sorti du volume de collision
	for player in ignored_players.duplicate():
		# Verifie que le joueur existe encore (reload de scene, mort, etc.)
		if not is_instance_valid(player):
			ignored_players.erase(player)
			continue
		var dist = player.global_position - global_position
		dist.y = 0
		if dist.length() > TILE_SIZE * 0.9:
			ignored_players.erase(player)
			remove_collision_exception_with(player)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if is_moving:
		velocity.x = move_direction.x * KICK_SPEED
		velocity.z = move_direction.z * KICK_SPEED
		move_and_slide()
		if is_on_wall():
			# Deferred pour eviter le crash physics_frame depuis _physics_process
			call_deferred("explode")
			is_moving = false
	else:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()

func snap_to_grid():
	var pos = global_position
	global_position = Vector3(
		round(pos.x / TILE_SIZE) * TILE_SIZE,
		pos.y,
		round(pos.z / TILE_SIZE) * TILE_SIZE
	)

func kick(direction: Vector3):
	if is_moving:
		return
	move_direction = get_cardinal_vector(direction)
	is_moving = true
	# On met le timer en pause pendant que la bombe est en deplacement
	$Timer.paused = true

func get_cardinal_vector(dir: Vector3) -> Vector3:
	if abs(dir.x) > abs(dir.z):
		return Vector3(sign(dir.x), 0, 0)
	else:
		return Vector3(0, 0, sign(dir.z))

func ignore_player(player: Node3D):
	if not ignored_players.has(player):
		ignored_players.append(player)
	add_collision_exception_with(player)

func _on_timer_timeout():
	explode()

func explode():
	if not is_inside_tree():
		return
	if blink_tween:
		blink_tween.kill()
	var explosion = EXPLOSION_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
	queue_free()

func start_blinking():
	blink_tween = create_tween().set_loops()
	blink_tween.tween_property($Sprite3D, "modulate", Color.RED, 0.15)
	blink_tween.tween_property($Sprite3D, "modulate", Color.WHITE, 0.15)
