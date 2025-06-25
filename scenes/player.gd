extends CharacterBody3D

@export_group('Physics')
@export_subgroup("Movement")
@export var WALK_SPEED = 5.0
@export var SPRINT_SPEED = 8.0
var speed: float
@export_subgroup('Jump')
@export var JUMP_VELOCITY = 4.5

@export_group('Mouse')
@export var MOUSE_SENSITIVITY = 0.003
@export_range(-180.0, 180.0) var MOUSE_LOOK_X_MIN: float = -90;
@export_range(-180.0, 180.0) var MOUSE_LOOK_X_MAX: float = 90;

@export_group('Head Bobbing')
@export var bob_frequency: float = 2.0
@export var bob_amplitude: float = 0.08
var t_bob: float = 0.0

@onready var head: Node3D = $head
@onready var camera_3d: Camera3D = $head/Camera3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_3d.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_3d.rotation.x = clamp(camera_3d.rotation.x, deg_to_rad(MOUSE_LOOK_X_MIN), deg_to_rad(MOUSE_LOOK_X_MAX))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("INPUT_JUMP") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if Input.is_action_pressed("INPUT_SPRINT") and is_on_floor():
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("INPUT_STRAFE_LEFT", "INPUT_STRAFE_RIGHT", "INPUT_FORWARD", "INPUT_BACKWARD")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = move_toward(velocity.x, 0, speed)
			velocity.z = move_toward(velocity.z, 0, speed)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
		
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera_3d.transform.origin = HeadBob(t_bob)

	move_and_slide()

func HeadBob(time: float):
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_frequency) * bob_amplitude
	pos.x = cos(time * bob_frequency / 2) * bob_amplitude
	
	return pos
