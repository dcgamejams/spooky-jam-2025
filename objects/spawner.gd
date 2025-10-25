extends Marker3D

@onready var ingredient = preload("res://objects/ingredient.tscn")

var timer = Timer.new()
var RANGE = 12.0
var MAX = 50.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(spawn_ingredient)
	add_child(timer)
	timer.start()
	
func spawn_ingredient():
	if get_tree().get_nodes_in_group("Balls").size() > MAX:
		return
	
	for i in randi_range(4, 9):
		var new_ingredient = ingredient.instantiate()
		var random_radians = randi_range(0, 360)
		new_ingredient.position = get_point_on_circumference(Vector2.ZERO, 16.0, random_radians)
		new_ingredient.initial_angle =  get_point_on_circumference(Vector2.ZERO, 16.0, random_radians - 10)
		# TODO: do not spawn in a circle around the cauldron (edge spawns)

		add_child(new_ingredient, true)
	
	timer.start(randi_range(8, 15))

func get_point_on_circumference(center: Vector2, radius: float, angle_radians) -> Vector3:
	var x = center.x + radius * cos(angle_radians)
	var y = center.y + radius * sin(angle_radians)
	return Vector3(x, 8.0, y)
	
