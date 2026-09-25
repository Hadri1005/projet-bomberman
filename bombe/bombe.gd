extends CharacterBody3D

const TILE_SIZE = 1.0
const KICK_SPEED = 6.0
const FUSE_TIME = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
const EXPLOSION_SCENE = preload("res://explosion/explosion.tscn")
var is_moving = false
var move_direction = Vector3.ZERO

func _ready():
	$Timer.wait_time = FUSE_TIME
	$Timer.one_shot = true
	$Timer.start()
	$Timer.timeout.connect(_on_timer_timeout)
	$Area3D.body_entered.connect(func(body): print("ENTERED: ", body.name))
	$Area3D.body_exited.connect(_on_area_body_exited)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if is_moving:
		velocity.x = move_direction.x * KICK_SPEED
		velocity.z = move_direction.z * KICK_SPEED
		move_and_slide()
		if is_on_wall():
			is_moving = false
			velocity.x = 0
			velocity.z = 0
			snap_to_grid()
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

func get_cardinal_vector(dir: Vector3) -> Vector3:
	if abs(dir.x) > abs(dir.z):
		return Vector3(sign(dir.x), 0, 0)
	else:
		return Vector3(0, 0, sign(dir.z))

func ignore_player(player: Node3D):
	add_collision_exception_with(player)

func _on_area_body_exited(body):
	print("EXITED: ", body.name)
	if body.is_in_group("player"):
		print("removing exception")
		remove_collision_exception_with(body)
		
func _on_timer_timeout():
	explode()

func explode():
	var explosion = EXPLOSION_SCENE.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
	queue_free()
