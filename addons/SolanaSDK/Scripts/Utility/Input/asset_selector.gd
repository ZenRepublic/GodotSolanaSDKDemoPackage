extends Node
class_name AssetSelector

@export var displayable_asset:DisplayableAsset
@export var display_system:AssetDisplaySystem

#set if you want for asset to be invisible before something is clicked
@export var asset_content:Control
@export var select_label:Label
@export var is_optional:bool=false

var selected_asset:WalletAsset
signal on_selected(selected_asset:WalletAsset)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	display_system.visible=false
	display_system.on_asset_selected.connect(select_asset)
	displayable_asset.on_selected.connect(show_display_system)
	
	if asset_content!=null:
		asset_content.visible=false
	if select_label != null:
		select_label.visible=true
	pass # Replace with function body.

func show_display_system(_selected_asset:DisplayableAsset) -> void:
	display_system.visible=true
	display_system.load_all_owned_assets()

func select_asset(display_selection:WalletAsset) -> void:
	if select_label != null:
		select_label.visible= (display_selection==null)
	if asset_content != null:
		asset_content.visible= (display_selection!=null)
		
	if display_selection == null:
		selected_asset = null
		displayable_asset.set_default_visual()
		on_selected.emit(null)
		return
	
	selected_asset = display_selection
	await displayable_asset.set_data(selected_asset)
	on_selected.emit(selected_asset)
	
func is_valid() -> bool:
	if selected_asset == null:
		return is_optional
	
	return selected_asset != null
	
func clear_selection() -> void:
	if selected_asset == null:
		return
	select_asset(null)
		
	
		
