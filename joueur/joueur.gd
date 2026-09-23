extends CharacterBody3D


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
@onready var bomb_label: Label = get_node("../HUD/BombContainer/BombLabel")

func _ready() -> void:
	current_health = max_health
	current_bombs = max_bombs
	update_heart_display()
	update_bomb_display()

func update_bomb_display() -> void:
	if bomb_label:
		bomb_label.text = "x" + str(current_bombs)

	
		
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
