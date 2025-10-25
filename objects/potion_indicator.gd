extends Control

var active : bool = false : set = set_active
var ingredient_desired: Ingredient.TYPE

var COLORS: Array[Color] = [Color.AQUA, Color.CRIMSON, Color.CORNFLOWER_BLUE, Color.DARK_GOLDENROD]

func _ready() -> void:
	set_active(active)
		
func	 set_active(value):
	%Control.visible = value

func set_required(type: Ingredient.TYPE):
	if type == 1:
		%Mushroom.hide()
	ingredient_desired = type
	var box: StyleBoxFlat = %Panel.get_theme_stylebox('panel')
	box.bg_color = COLORS[type]
	box.bg_color.a = 0.5
	
