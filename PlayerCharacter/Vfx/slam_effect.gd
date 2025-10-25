@tool
extends Node3D

@onready var torus: TorusMesh = $SlamMesh.mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	torus.surface_get_material(0).albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	slam()

var slam_amount = 1.3
var timing = 0.2

func slam():
	#create a tween that simulate a compression of the model (squash and strech ones)
	#maily used to accentuate game feel/juice
	#call the squash_and_strech function of the model (it's this function that actually squash and strech the model)
	var sasTween: Tween = create_tween()
	sasTween.set_ease(Tween.EASE_OUT)
	sasTween.set_parallel(true)
	sasTween.tween_property(torus, "inner_radius", 1.9, timing).from(0.2)
	sasTween.tween_property(torus, "outer_radius", 2.4, timing).from(0.7)
	sasTween.tween_callback(fade)
	
func fade():
	await get_tree().create_timer(0.25).timeout
	var mat = torus.surface_get_material(0)
	var fadeTween: Tween = create_tween()
	fadeTween.set_ease(Tween.EASE_OUT)
	fadeTween.tween_property(mat, "albedo_color", Color(1.0, 1.0, 1.0, 0.0), 0.5)
	fadeTween.tween_callback(func(): destroy())
	
	
func destroy():
	if not Engine.is_editor_hint():
		queue_free()
