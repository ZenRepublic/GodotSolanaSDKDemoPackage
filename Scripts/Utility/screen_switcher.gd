extends Node
class_name ScreenSwitcher

@export var starting_panel:Node
var curr_active_panel:Node
var prev_panel:Node
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	curr_active_panel = starting_panel


func switch_active_panel(new_active_panel:Node) -> void:
	if curr_active_panel!=null:
		curr_active_panel.visible = false
		prev_panel = curr_active_panel
		
	if new_active_panel!=null:
		new_active_panel.visible=true
	curr_active_panel = new_active_panel
	
	
func back_to_previous_panel() -> void:
	if curr_active_panel!=null:
		curr_active_panel.visible=false
	
	prev_panel.visible=true
	
	var temp_panel = curr_active_panel
	curr_active_panel = prev_panel
	prev_panel = temp_panel
	

func close_active_panel()->void:
	if curr_active_panel!=null:
		curr_active_panel.visible=false
		curr_active_panel=null
	
