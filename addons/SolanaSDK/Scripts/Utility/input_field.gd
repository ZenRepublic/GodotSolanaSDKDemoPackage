extends LineEdit
class_name InputField

enum InputType{Alphanumeric,Integer,FractionNumber}

@export var input_type = InputType.Alphanumeric
@export var min_length:int = 0
@export var is_optional = false

@export_category("Number Field Settings")
@export var min_value:float = 0.0
@export var max_value:float = 999.0


var fraction_regex = "^[0-9.]*$"
var integer_regex = "^[0-9]+$"
var alphanumeric_regex = "^[a-zA-Z0-9]+$"

@onready var input_constraint = RegEx.new()

signal on_field_updated

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text_changed.connect(handle_text_change)
	text_submitted.connect(handle_text_submit)
	match input_type:
		InputType.Alphanumeric:
			input_constraint.compile(alphanumeric_regex)
		InputType.Integer:
			input_constraint.compile(integer_regex)
		InputType.FractionNumber:
			input_constraint.compile(fraction_regex)
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
var old_text = ""
func handle_text_change(new_text: String) -> void:
	if new_text.length() < min_length:
		new_text = old_text
	
	on_field_updated.emit()
	old_text = text
	
func handle_text_submit(new_text:String) -> void:
	text = adjust_text(new_text)
	release_focus()
	
func adjust_text(new_text:String) -> String:
	var adjusted_text:String = new_text
	if input_constraint.search(new_text):
			if input_type == InputType.Integer:
				var value:int = int(new_text)
				print(value)
				value = clamp(value,int(get_min_value()),int(get_max_value()))
				adjusted_text = str(value)
			if input_type == InputType.FractionNumber:
				var value:float = float(new_text)
				value = clamp(value,get_min_value(),get_max_value())
				adjusted_text = str(value)
	else:
		adjusted_text = old_text
	
	return adjusted_text
		
	
	
func get_min_value() -> float:
	if min_value == -1:
		return -INF
	else:
		return min_value
		
func get_max_value() -> float:
	if max_value == -1:
		return INF
	else:
		return max_value
	
		
func is_valid() -> bool:
	if text.length() < min_length:
		return false
	if !is_optional && text.length()==0:
		return false
		
	return true
	
