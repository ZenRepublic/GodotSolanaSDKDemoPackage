extends Node
class_name WalletAdapterUI

@export var provider_button_scn:PackedScene
@export var provider_names:Array[String]
@export var provider_images:Array[Texture]

@export var selection_spawn:Container

signal on_provider_selected

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func setup(available_wallets) -> void:
	print(available_wallets)
	for i in range(available_wallets.size()):
		var provider_id = available_wallets[i]
		var button_instance:WalletAdapterButton = provider_button_scn.instantiate()
		button_instance.set_data(provider_id,provider_names[provider_id],provider_images[provider_id])
		selection_spawn.add_child(button_instance)
		
		
		
