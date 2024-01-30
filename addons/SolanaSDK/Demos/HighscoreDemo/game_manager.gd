extends Node

@export var button:ButtonLock
@onready var soar_program:SoarProgram=$SoarProgram

#devnet Game account, created once using setup_game function
var game_address:String = "8ewcHXrpmwGRAVU9TndiUXfEEFqVu7vbthPZzkW55CYD"
#devned leaderboard No.1 created from the game. Players can submit their scores to it
var leaderboard_address:String = "6iorenkNgoZvyMB1Vcyn4mkx5nxk8qMHTbGrPkTiBh98"
#collection used as nft_meta for games and leaderboards. this is devnet Rubians
var nft_collection:String = "EE1XTVRxVX5UtTLKRg7Y5bFQEKm2wm2nao9SGF27fypH"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneLoader.emit_signal("scene_loaded")
	
	button.pressed.connect(register_leaderboard)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func setup_game() -> void:
	var game_attributes:SoarUtils.GameAttributes = SoarUtils.GameAttributes.new()
	game_attributes.title="Test Game"
	game_attributes.description="Best Game ever"
	#game's collection nft. Rubians provided by default
	game_attributes.nft_meta = Pubkey.new_from_string(nft_collection)
	
	soar_program.init_game(game_attributes)


func register_leaderboard() -> void:
	var leaderboard_data:SoarUtils.LeaderboardData = SoarUtils.LeaderboardData.new()
	leaderboard_data.description="The first leaderboard win big in 24 hours!"
	leaderboard_data.nft_meta = Pubkey.new_from_string(nft_collection)
	leaderboard_data.set_decimals(0)
	leaderboard_data.set_scores_to_retain(10)
	leaderboard_data.is_ascending=true
	leaderboard_data.allow_multiple_scores=true
	
	soar_program.add_leaderboard(game_address,leaderboard_data)
	

func initialize_player() -> void:
	var username:String = "Rubian"
	#devnet rubian nft example
	var user_nft:Pubkey = Pubkey.new_from_string("9aNFiE6mdcQSGaytpoqpWvJMeA2h6vDa4sJttsyyKFPA")
	
	soar_program.initialize_player(username,user_nft)
