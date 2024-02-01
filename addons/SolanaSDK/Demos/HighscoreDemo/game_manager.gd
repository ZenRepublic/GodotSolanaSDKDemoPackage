extends Node

@onready var soar_program:SoarProgram=$SoarProgram
@onready var start_screen=$StartingScreen
@onready var play_screen = $PlayScreen
@onready var leaderboard_screen=$LeaderboardScreen

@export var start_game_button:Button
@export var score_label:Label
@export var submit_score_button:Button
@export var leaderboard_button:Button

@export var leaderboard_system:LeaderboardSystem

var player_score:int

#devnet Game account, created once using setup_game function
var game_address:String = "8ewcHXrpmwGRAVU9TndiUXfEEFqVu7vbthPZzkW55CYD"
#devned leaderboard No.1 created from the game. Players can submit their scores to it
var leaderboard_address:String = "6iorenkNgoZvyMB1Vcyn4mkx5nxk8qMHTbGrPkTiBh98"
#collection used as nft_meta for games and leaderboards. this is devnet Rubians
var nft_collection:String = "EE1XTVRxVX5UtTLKRg7Y5bFQEKm2wm2nao9SGF27fypH"

#THIS IS VERY UNSAFE!! 
#For players to submit scores, they need the game's authority (set in init_game) to sign as well
#So that players couldnt just sign the transaction without playing the game with setting any score
#For a test, we have exposed the authority so sign along the player

#For production, you need to store the keypair in some server, and send the serialized transaction
#for the server to sign with that keypair and return the signed transaction to send it out.
var game_authority:String = "E2Tf3ws9uekoVC5ZGxRKXzpchShT7GHhiphmzJxEjvFRTnBXT8y3zJtoxYWLMkVSBiCH1nqZj3Hrmu3tX3Tffuq"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneLoader.emit_signal("scene_loaded")
	
	start_game_button.pressed.connect(update_leaderboard)
	submit_score_button.pressed.connect(submit_score)
	leaderboard_button.pressed.connect(show_leaderboard)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func start_game() -> void:
	#check if this wallet is initialized as a player in SOAR program
	#if not, initialize and then start
	
	var player_data:Dictionary = soar_program.fetch_player_data(SolanaService.wallet.get_pubkey())
	print(player_data)
	if player_data.size()==0:
		initialize_player()
	else:
		play()
		
func play() -> void:
	start_screen.visible=false
	play_screen.visible=true
	
	player_score = randi_range(1,420)
	score_label.text = str(player_score)
	
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
	
func update_leaderboard() -> void:
	var leaderboard_data:SoarUtils.LeaderboardData = SoarUtils.LeaderboardData.new()
	leaderboard_data.description="Brand new leaderboard, win big in 24 hours!"
	leaderboard_data.nft_meta = Pubkey.new_from_string(nft_collection)
	leaderboard_data.is_ascending=false
	leaderboard_data.allow_multiple_scores=true
	
	soar_program.update_leaderboard(game_address,leaderboard_address,leaderboard_data)
	

func initialize_player() -> void:
	var username:String = "Rubian"
	#devnet rubian nft example
	var user_nft:Pubkey = Pubkey.new_from_string("9aNFiE6mdcQSGaytpoqpWvJMeA2h6vDa4sJttsyyKFPA")
	
	soar_program.on_player_initialized.connect(play)
	soar_program.initialize_player(username,user_nft)
	
func submit_score() -> void:
	var game_account:Pubkey = Pubkey.new_from_string(game_address)
	var leaderboard_account:Pubkey = Pubkey.new_from_string(leaderboard_address)
	
	var seed = SolanaSDK.bs58_decode(game_authority)
	var auth_keypair = Keypair.new_from_seed(seed)
	soar_program.on_score_submitted.connect(return_to_menu)
	soar_program.submit_score_to_leaderboard(game_account,leaderboard_account,auth_keypair,player_score)
	
func return_to_menu() -> void:
	soar_program.on_score_submitted.disconnect(return_to_menu)
	start_screen.visible=true
	play_screen.visible=false
	
func show_leaderboard() -> void:
	var leaderboard_scores:Dictionary = soar_program.fetch_leaderboard_scores(Pubkey.new_from_string(leaderboard_address))
	var player_scores:Dictionary = soar_program.fetch_player_scores(SolanaService.wallet.get_pubkey(),Pubkey.new_from_string(leaderboard_address))
	leaderboard_system.refresh(leaderboard_scores,player_scores)
	start_screen.visible=false
	leaderboard_screen.visible=true
