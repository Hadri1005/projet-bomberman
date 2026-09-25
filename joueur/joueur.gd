extends CharacterBody3D

const BOMB_SCENE = preload("res://bombe/bombe.tscn")
const TILE_SIZE = 2.0
const SPEED = 5.0
@export var max_health: int = 3
var current_health: int
var last_direction: String = "south"
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var heart_container: HBoxContainer = get_node("../HUD/HeartContainer")
@export var spawn_point: Vector3 = Vector3(0, 0, 0)
const HEART_IMAGE = preload("res://assets/IconsOutline_16px/Icon51.png")
@export var max_bombs: int = 5
var current_bombs: int
var bombs_placed = 0
var last_move_direction = Vector3.FORWARD

func _ready() -> void:
	current_health = max_health
	current_bombs = max_bombs
	update_heart_display()

	
		
func take_damage() -> void:
	current_health = clampi(current_health - 1, 0, max_health)
	update_heart_display()
	global_position = spawn_point 
	print("Current Health: ", current_health)
	if current_health <= 0:
		die()

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


func die() -> void:
	print("Player died!")
	var death_screen = get_node_or_null("../mort")
	if death_screen:
		death_screen.show()
	get_tree().paused = true
	
func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		last_direction = get_cardinal_direction(direction)
		sprite.play("walk_" + last_direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		sprite.play("idle_" + last_direction)

	move_and_slide()
	
func get_cardinal_direction(dir: Vector3) -> String:
	var angle := atan2(dir.x, dir.z)
	var angle_deg := rad_to_deg(angle)
	
	if angle_deg > -45 and angle_deg <= 45:
		return "south" 
	elif angle_deg > 45 and angle_deg <= 135:
		return "east" 
	elif angle_deg > -135 and angle_deg <= -45:
		return "west" 
	else:
		return "north"
		
func _on_button_pressed() -> void:
	take_damage() # Replace with function body.
	
func _input(event):
	if event.is_action_pressed("place_bomb") and bombs_placed < max_bombs:
		place_bomb()
	if event.is_action_pressed("kick_bomb"):
		try_kick_bomb()

func place_bomb():
	var bomb = BOMB_SCENE.instantiate()
	get_tree().current_scene.add_child(bomb)
	bomb.global_position = global_position.snapped(Vector3.ONE * TILE_SIZE)
	bomb.ignore_player(self)
	bombs_placed += 1
	bomb.tree_exited.connect(func(): bombs_placed -= 1)

func try_kick_bomb():
	# on tire un raycast dans la direction où regarde le joueur
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var to = from + last_move_direction * (TILE_SIZE * 0.7)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	if result and result.collider.has_method("kick"):
		result.collider.kick(last_move_direction)
