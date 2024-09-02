extends Node
class_name NftDisplaySystem

@export var displayable_nft_scn:PackedScene
@export var collection_filter:Array[NFTCollection]
@export var container:Container
@export var no_nft_overlay:Control
@export var nft_size:int = 196

@export var load_all:bool
@export var close_on_select:bool
@export var destroy_on_close:bool

var displayables:Array[DisplayableNFT]

signal on_display_updated
signal on_nft_selected(nft:Nft)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	on_display_updated.connect(handle_display_update)
	if load_all:
		load_all_nfts()
		
func load_all_nfts() -> void:
	SolanaService.asset_manager.on_asset_loaded.connect(add_to_list)
	SolanaService.asset_manager.on_asset_load_finished.connect(asset_load_finished)
	
#	load all nfts that have already been loaded and then add new ones as they load
	get_loaded_nfts()
	
	if !SolanaService.asset_manager.assets_loaded:
		SolanaService.asset_manager.load_assets()
	

func get_loaded_nfts() -> void:
	if collection_filter.size()==0:
		setup(SolanaService.asset_manager.get_owned_nfts())
	else:
		for collection in collection_filter:
			setup(SolanaService.asset_manager.get_nfts_from_collection(collection))

func setup(nfts:Array[Nft],clear_previous:bool=false) -> void:
	if clear_previous && displayables.size()!=null:
		clear_display()
	
	if nfts.size()==0:
		return
		
	for nft in nfts:
		add_to_list(nft)
		
func add_to_list(asset:WalletAsset) -> void:
	if !asset is Nft:
		return
		
	var pass_collection_filter= (collection_filter.size()==0)
	for collection in collection_filter:
		if collection.belongs_to_collection(asset):
			pass_collection_filter=true
			break
	if !pass_collection_filter:
		return
		
	var displayable_nft:DisplayableNFT = displayable_nft_scn.instantiate()
	displayable_nft.custom_minimum_size = Vector2(nft_size,nft_size)
	container.add_child(displayable_nft)
		
	displayable_nft.set_data(asset)
	displayables.append(displayable_nft)
	displayable_nft.on_selected.connect(handle_displayable_selection)
	
	on_display_updated.emit()
	
func asset_load_finished(owned_assets:Array[WalletAsset])->void:
	on_display_updated.emit()
	pass
	
func handle_displayable_selection(selected_nft:DisplayableNFT) -> void:
	on_nft_selected.emit(selected_nft.nft)
	if close_on_select:
		close()
		
func select_none() -> void:
	on_nft_selected.emit(null)
	if close_on_select:
		close()
		
func clear_display() -> void:
	for nft in displayables:
		nft.queue_free()
	
	displayables.clear()
	on_display_updated.emit()
	
func handle_display_update() -> void:
	if no_nft_overlay!=null:
		no_nft_overlay.visible = (displayables.size()==0)
	
func close() -> void:
	self.visible = false
	if destroy_on_close:
		queue_free()
