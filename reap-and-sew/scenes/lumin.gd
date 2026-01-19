extends CharacterBody2D

@export var jump_speed := 200.0
@export var walk_speed := 100.0
@export var run_speed := 200.0
@export var dash_speed:= 200.0

@export var ground_accel := 10.0
@export var air_accel := 10.0
@export var ground_friction := 6.0
@export var stop_speed := 2.19

var wish_dir := 0.0
var wish_speed := 0.0
var jump_queue := false
var can_dash := true
var dash_dir := 1
var dash_cd:=0.0
# mouse capture shite
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# if in air hold jump touch the ground u jump
func input_buffer(pressed, released, queue) -> bool:
	if released:
		return false
	return pressed or queue

func apply_friction(delta: float) -> void: ## Applies Friction
	var speed: float = abs(velocity.x)
	if speed == 0.0:
		return

	var control: float = stop_speed if speed < stop_speed else speed
	var drop: float = control * ground_friction * delta

	var new_speed: float = speed - drop
	if new_speed < 0.0:
		new_speed = 0.0

	if speed > 0.0:
		velocity.x *= new_speed / speed

## quake acceleration
func accelerate(accel: float, delta: float) -> void:
	var current_speed := velocity.x * wish_dir
	var add_speed := wish_speed - current_speed
	if add_speed <= 0.0:
		return

	var accel_speed := accel * wish_speed * delta
	if accel_speed > add_speed:
		accel_speed = add_speed

	velocity.x += accel_speed * wish_dir

# apply ground friction
func _handle_ground_physics(delta: float) -> void:
	apply_friction(delta)
	accelerate(ground_accel, delta)

# apply gravity air has no friction
func _handle_air_physics(delta: float) -> void:
	accelerate(air_accel, delta)
	velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

func _physics_process(delta: float) -> void:
	var input_x := Input.get_axis("left", "right")

	wish_dir = sign(input_x)
	
	
	@warning_ignore("incompatible_ternary") # idk why its raising this, i think theyre both ints?
	dash_dir = wish_dir if wish_dir != 0 else dash_dir
	
	
	# expected max speed
	wish_speed = run_speed if Input.is_action_pressed("run") else walk_speed
	
	
	if Input.is_action_pressed("dash") and can_dash:
		can_dash = false
		dash_cd = 1
		velocity.x += dash_speed * dash_dir
	dash_cd -= delta
	
	if dash_cd <= 0:
		can_dash = true
	jump_queue = input_buffer(Input.is_action_just_pressed("jump"), Input.is_action_just_released("jump"), jump_queue)
	
	if is_on_floor():
		if jump_queue:
			velocity.y = -jump_speed	# boing boing
			jump_queue = false
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)

	move_and_slide()
