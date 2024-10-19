extends Node
class_name AccountDisplaySystem

@export var container:Container
@export var entry_scn:PackedScene
@export var no_entries_overlay:Control
@export var bring_new_to_back:bool=true
@export var refresh_button:BaseButton

var accounts:Array[AccountDisplayEntry]

var list_data:Dictionary

signal on_account_added(account_entry:AccountDisplayEntry)
signal on_account_selected(account_data:Dictionary)

func _ready() -> void:
	if no_entries_overlay!=null:
		no_entries_overlay.visible=true
	
	if refresh_button!=null:
		refresh_button.pressed.connect(refresh_account_list)
		
func set_list(program:AnchorProgram,account_keyword:String, identifier_keyword:String,filter:Array=[], spawn_accounts:bool=true) -> void:
	list_data = {
		"program":program,
		"acc_key": account_keyword,
		"id_key":identifier_keyword,
		"filter":filter
	}
	
	if spawn_accounts:
		refresh_account_list()
	
	
func refresh_account_list() -> void:
	if list_data.size() == 0:
		return
	
	clear_display()
	
	if refresh_button!=null:
		refresh_button.disabled=true
		
	if no_entries_overlay!=null:
		no_entries_overlay.visible=true
	
	
	var accounts:Dictionary = await SolanaService.fetch_all_program_accounts_of_type(list_data["program"],list_data["acc_key"],list_data["filter"])
	for key in accounts.keys():
		var data:Dictionary = accounts[key]
		var identifier = data[list_data["id_key"]]
		#identifier needs to be a string to give it to label. if packed byte array, then convert to string		
		#check against array variants: https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#enum-globalscope-variant-type			
		if typeof(identifier) in [28,29,30,31,32,33]:
			var identifier_bytes:PackedByteArray = identifier as PackedByteArray
			identifier = identifier_bytes.get_string_from_utf8()
		elif typeof(identifier) != TYPE_STRING:
			identifier = str(identifier)
			
		add_account(identifier,data)
		
	if refresh_button!=null:
		refresh_button.disabled=false
	

func add_account(account_name:String,account_data:Dictionary) -> void:
	if no_entries_overlay!=null:
		no_entries_overlay.visible=false
		
	var entry_instance:AccountDisplayEntry = entry_scn.instantiate() as AccountDisplayEntry
	
	container.add_child(entry_instance)
	if bring_new_to_back:
		container.move_child(entry_instance,0)
	
	await entry_instance.setup_account_entry(account_name,account_data)
	entry_instance.on_selected.connect(handle_press)
	accounts.append(entry_instance)
	on_account_added.emit(entry_instance)
	
func handle_press(selected_account:AccountDisplayEntry) -> void:
	on_account_selected.emit(selected_account.data)
	
func clear_display() -> void:
	for account in accounts:
		account.on_selected.disconnect(handle_press)
		account.queue_free()
	accounts.clear()
