extends Node
class_name ModelNFT

@export var loading_template:Node3D

var nft:Nft
var model:Node3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_model(nft:Nft) -> void:
	self.nft = nft
	
	var gltf_document:GLTFDocument = GLTFDocument.new()
	if nft.model_state!=null:
		instantiate_model(nft.model_state)
	else:
		await nft.load_model()
		if nft.model_state!=null:
			instantiate_model(nft.model_state)
		else:
			print("Couldn't load the model for mint: %s" % nft.mint.get_value())
	
	loading_template.visible=false
			
			
func instantiate_model(state:GLTFState) -> void:
	var gltf_document:GLTFDocument = GLTFDocument.new()
	var gltf_extension:GLTFDocumentExtension = GLTFDocumentExtension.new()
	gltf_document.register_gltf_document_extension(gltf_extension)
	print(state.json)
	model = gltf_document.generate_scene(nft.model_state)
	add_child(model)
	self.name = nft.metadata.get_token_name()
