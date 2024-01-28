extends Node

@export var button:ButtonLock
@onready var soar_program:SoarProgram=$SoarProgram

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneLoader.emit_signal("scene_loaded")
	
	button.pressed.connect(on_button_press)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func on_button_press() -> void:
	var game_attributes:SoarUtils.GameAttributes = SoarUtils.GameAttributes.new()
	game_attributes.title="Test Game"
	game_attributes.description="Best Game ever"
	#game's collection nft. Rubians provided by default
	game_attributes.nft_meta = Pubkey.new_from_string("9pg23GZKceX1pfVCwG1cfWXG2qJknbhejWGqkuH8hYY8")
	
	soar_program.init_game(game_attributes)
