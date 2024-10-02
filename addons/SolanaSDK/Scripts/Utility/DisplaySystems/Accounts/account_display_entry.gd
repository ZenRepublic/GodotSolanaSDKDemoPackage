extends Node
class_name AccountDisplayEntry

@export var label:Label
@export var button:BaseButton

var data:Dictionary

signal on_selected(account:AccountDisplayEntry)

func setup_account_entry(name:String,account_data:Dictionary) -> void:
	data = account_data
	label.text = name
	button.pressed.connect(select)
	
func select() -> void:
	on_selected.emit(self)
	
