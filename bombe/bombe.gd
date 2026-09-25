extends CharacterBody3D

const TILE_SIZE = 1.0
const KICK_SPEED = 6.0
const FUSE_TIME = 3.0

var is_moving = false
var move_direction = Vector3.ZERO

func _ready():
	$Timer.wait_time = FUSE_TIME
	$Timer.one_shot = true
	$Timer.start()
	$Timer.timeout.connect(_on_timer_timeout)
	$Area3D.body_exited.connect(_on_area_body_exited)

func _physics_process(delta):
	if is_moving:
		var collision = move_and_collide(move_direction * KICK_SPEED * delta)
		if collision:
			# a tapé un mur ou un obstacle -> s'arrête et se réaligne sur la grille
			is_moving = false
			velocity = Vector3.ZERO
			global_position = global_position.snapped(Vector3.ONE * TILE_SIZE)

func kick(direction: Vector3):
	if is_moving:
		return
	move_direction = direction.normalized()
	move_direction.y = 0  # on ne kick pas verticalement
	is_moving = true

func ignore_player(player: Node3D):
	add_collision_exception_with(player)
	
func _on_area_body_exited(body):
	if body.is_in_group("player"):
		remove_collision_exception_with(body)

func _on_timer_timeout():
	explode()

func explode():
	# instancie ici ta scène Explosion, vérifie les murs destructibles, etc.
	queue_free()
