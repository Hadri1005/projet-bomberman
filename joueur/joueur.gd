extends CharacterBody3D

signal died(player)

@export var prefix: String = "p1"
@export var nom: String = "Joueur 1"
@export var heart_container: HBoxContainer
@export var score_label: Label
@export var spawn_point: Vector3 = Vector3(0.5, 0.8, 0.5)
@export var max_health: int = 3
@export var max_bombs: int = 1

@onready var grid_map: GridMap = get_node("../GridMap")
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

const BOMB_SCENE = preload("res://bombe/bombe.tscn")
const HEART_IMAGE = preload("res://assets/IconsOutline_16px/Icon51.png")
const TILE_SIZE = 1.0
const SPEED = 5.0

var current_health: int
var kills: int = 0
var last_direction: String = "south"
var bombs_placed = 0
var last_move_direction = Vector3.FORWARD
var bomb_radius: int = 1

func _ready() -> void:
	current_health = max_health
	update_heart_display()
	update_score_label()
	if prefix == "p2":
		sprite.modulate = Color(1, 0, 0)

func add_kill() -> void:
	kills += 1
	update_score_label()

func update_score_label() -> void:
	if score_label:
		score_label.text = "%s : %d kills" % [nom, kills]

func take_damage() -> void:
	$hitsound.play()
	current_health = clampi(current_health - 1, 0, max_health)
	update_heart_display()
	global_position = spawn_point
	if current_health <= 0:
		die()

func die() -> void:
	died.emit(self)

func update_heart_display() -> void:
	if not heart_container:
		return
	for child in heart_container.get_children():
		child.queue_free()
	for i in range(current_health):
		var texture_rect = TextureRect.new()
		texture_rect.texture = HEART_IMAGE
		texture_rect.custom_minimum_size = Vector2(32, 32)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_container.add_child(texture_rect)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector(prefix + "_left", prefix + "_right", prefix + "_up", prefix + "_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		last_direction = get_cardinal_direction(direction)
		last_move_direction = direction
		sprite.play("walk_" + last_direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		sprite.play("idle_" + last_direction)

	move_and_slide()

func get_cardinal_direction(dir: Vector3) -> String:
	var angle_deg := rad_to_deg(atan2(dir.x, dir.z))
	if angle_deg > -45 and angle_deg <= 45:
		return "south"
	elif angle_deg > 45 and angle_deg <= 135:
		return "east"
	elif angle_deg > -135 and angle_deg <= -45:
		return "west"
	else:
		return "north"

func _input(event):
	if event.is_action_pressed(prefix + "_bomb") and bombs_placed < max_bombs:
		place_bomb()
	if event.is_action_pressed(prefix + "_kick"):
		try_kick_bomb()

func place_bomb():
	var bomb = BOMB_SCENE.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.explosion_radius = bomb_radius
	bomb.owner_player = self   # <-- pour attribuer les kills

	var cell = grid_map.local_to_map(grid_map.to_local(global_position))
	var snapped_pos = grid_map.to_global(grid_map.map_to_local(cell))
	bomb.global_position = Vector3(snapped_pos.x, global_position.y - 0.5, snapped_pos.z)
	bomb.ignore_player(self)
	bombs_placed += 1
	bomb.tree_exited.connect(func(): bombs_placed -= 1)

func try_kick_bomb():
	var kick_dir = get_cardinal_vector(last_move_direction)
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var to = from + kick_dir * (TILE_SIZE * 1.2)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	if result and result.collider.has_method("kick"):
		result.collider.kick(kick_dir)

func get_cardinal_vector(dir: Vector3) -> Vector3:
	if abs(dir.x) > abs(dir.z):
		return Vector3(sign(dir.x), 0, 0)
	else:
		return Vector3(0, 0, sign(dir.z))

func add_bomb_capacity(amount: int = 1) -> void:
	max_bombs += amount

func add_explosion_radius(amount: int) -> void:
	bomb_radius += amount
