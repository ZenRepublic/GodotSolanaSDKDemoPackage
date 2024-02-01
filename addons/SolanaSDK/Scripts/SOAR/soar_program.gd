extends Node
class_name SoarProgram

#for building custom program instructions, first goes function name, then array of accounts
#and then variables to pass in

#IMPORTANT:
#if no variables need to be passed in, write 'null'
#if multiple variables, put them in a dictionary
#if the variable is a class, pass it in as dictionary

@onready var soar_program:AnchorProgram = $SOAR_PROGRAM

signal on_game_initialized
signal on_leaderboard_added
signal on_leaderboard_updated
signal on_player_initialized
signal on_player_updated
signal on_score_submitted

func get_pid() -> Pubkey:
		return Pubkey.new_from_string(soar_program.get_pid())
		
func fetch_game_data(game_account:Pubkey) -> Dictionary:
	return soar_program.fetch_account("Game",game_account)
	
func fetch_leaderboard_data(leaderboard_account:Pubkey) -> Dictionary:
	return soar_program.fetch_account("LeaderBoard",leaderboard_account)
	
func fetch_leaderboard_scores(leaderboard_account:Pubkey) -> Dictionary:
	var leaderboard_top_entries_pda:Pubkey = SoarPDA.get_leaderboard_scores_pda(leaderboard_account,get_pid())
	return soar_program.fetch_account("LeaderTopEntries",leaderboard_top_entries_pda)
	
func fetch_player_data(user_account:Pubkey) -> Dictionary:
	var player_pda:Pubkey = SoarPDA.get_player_pda(user_account,get_pid())
	return soar_program.fetch_account("Player",player_pda)
	
func fetch_player_data_from_pda(player_pda:Pubkey) -> Dictionary:
	return soar_program.fetch_account("Player",player_pda)

func fetch_player_scores(user_account:Pubkey,leaderboard_account:Pubkey) -> Dictionary:
	var player_account_pda:Pubkey = SoarPDA.get_player_pda(user_account,get_pid())
	var player_scores_pda:Pubkey = SoarPDA.get_player_scores_pda(player_account_pda,leaderboard_account,get_pid())
	print(player_scores_pda.get_value())
	return soar_program.fetch_account("PlayerScoresList",player_scores_pda)

func init_game(game_attributes:SoarUtils.GameAttributes) -> void:
	var game_account:Keypair = SolanaService.generate_keypair()
	var instructions:Array[Instruction]
	var init_game_ix:Instruction = soar_program.build_instruction("initializeGame",[
		SolanaService.wallet.get_kp(), #creator
		game_account, #game
		Pubkey.new_from_string("11111111111111111111111111111111") #system program
	],{
		"GameMeta":game_attributes.get_value(),
		"GameAuth":[SolanaService.wallet.get_pubkey()]
	})
	
	print("Creating Game Account with ID: %s"%game_account.get_public_value())
	instructions.append(init_game_ix)
	SolanaService.transaction_processor.connect("on_transaction_finish",init_game_response)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)
	
func init_game_response(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",init_game_response)
	if transaction_id!="":
		emit_signal("on_game_initialized")
		

	
func add_leaderboard(game_address:String,leaderboard_data:SoarUtils.LeaderboardData) -> void:
	var game_account:Pubkey=Pubkey.new_from_string(game_address)
	var game_data:Dictionary = fetch_game_data(game_account)
	
	if game_data.size() == 0:
		push_error("Failed to fetch the game data")
		return
		
	var leaderboard_id:int = game_data["leaderboardCount"]+1
	var leaderboard:Pubkey = SoarPDA.get_leaderboard_pda(game_account,leaderboard_id,get_pid())
	var leaderboard_top_entries:Pubkey = SoarPDA.get_leaderboard_scores_pda(leaderboard, get_pid())
	
	var instructions:Array[Instruction]
	var add_leaderboard_ix:Instruction = soar_program.build_instruction("addLeaderboard",[
		SolanaService.wallet.get_kp(), #game authority
		SolanaService.wallet.get_kp(), #payer
		game_account, #game
		leaderboard, #leaderboard PDA
		leaderboard_top_entries, #top entries PDA
		SystemProgram.get_pid() #system program
	],
	leaderboard_data.get_value())
	
	print("Creating Leaderboard with ID: %s"%leaderboard.get_value())
	
	instructions.append(add_leaderboard_ix)
	SolanaService.transaction_processor.connect("on_transaction_finish",add_leaderboard_callback)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)
	
func add_leaderboard_callback(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",add_leaderboard_callback)
	if transaction_id!="":
		emit_signal("on_leaderboard_added")
	
func update_leaderboard(game_address:String,leaderboard_address:String,leaderboard_data:SoarUtils.LeaderboardData) -> void:
	var game_account:Pubkey=Pubkey.new_from_string(game_address)
	var leaderboard_account:Pubkey = Pubkey.new_from_string(leaderboard_address)
	var leaderboard_top_entries:Pubkey = SoarPDA.get_leaderboard_scores_pda(leaderboard_account, get_pid())

	var instructions:Array[Instruction]
	var update_leaderboard_ix:Instruction = soar_program.build_instruction("updateLeaderboard",[
		SolanaService.wallet.get_kp(), #game authority
		game_account, #game
		leaderboard_account, #leaderboard 
		leaderboard_top_entries #top entries PDA
	],{
		"newDescription":AnchorProgram.option(leaderboard_data.get_value()["description"]),
		"newNftMeta":AnchorProgram.option(leaderboard_data.get_value()["nft_meta"]),
		"newMinScore":leaderboard_data.get_value()["min_score"],
		"newMaxScore":leaderboard_data.get_value()["max_score"],
		"newIsAscending":AnchorProgram.option(leaderboard_data.get_value()["is_ascending"]),
		"newAllowMultipleScores":AnchorProgram.option(leaderboard_data.get_value()["allow_multiple_scores"])
	})
	
	print("Updating Leaderboard with ID: %s"%leaderboard_account.get_value())
	
	instructions.append(update_leaderboard_ix)
	SolanaService.transaction_processor.connect("on_transaction_finish",update_leaderboard_callback)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)
	
func update_leaderboard_callback(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",update_leaderboard_callback)
	if transaction_id!="":
		emit_signal("on_leaderboard_updated")
	

func initialize_player(username:String, user_nft:Pubkey) -> void:
	var player_account:Pubkey = SoarPDA.get_player_pda(SolanaService.wallet.get_pubkey(),get_pid())
	var instructions:Array[Instruction]
	var init_player_ix:Instruction = soar_program.build_instruction("initializePlayer",[
		SolanaService.wallet.get_kp(), #payer
		SolanaService.wallet.get_kp(), #user
		player_account, #player PDA
		SystemProgram.get_pid() #system program
	],{
		"username":username,
		"nftMeta":user_nft
	})
	
	print("Initializing Player account with ID: %s"%player_account.get_value())
	instructions.append(init_player_ix)
	SolanaService.transaction_processor.connect("on_transaction_finish",initialize_player_response)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)
	
	
func initialize_player_response(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",initialize_player_response)
	if transaction_id!="":
		emit_signal("on_player_initialized")
		
func update_player(username:String, user_nft:Pubkey) -> void:
	var player_account:Pubkey = SoarPDA.get_player_pda(SolanaService.wallet.get_pubkey(),get_pid())
	
	var instructions:Array[Instruction]
	var update_player_ix:Instruction = soar_program.build_instruction("updatePlayer",[
		SolanaService.wallet.get_kp(), #user
		player_account, #player PDA
	],{
		"username":AnchorProgram.option(username),
		"nftMeta":AnchorProgram.option(user_nft)
	})
	
	print("Updating Player account with ID: %s"%player_account.get_value())
	instructions.append(update_player_ix)
	SolanaService.transaction_processor.connect("on_transaction_finish",update_player_response)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)

func update_player_response(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",update_player_response)
	if transaction_id!="":
		emit_signal("on_player_updated")
		

func submit_score_to_leaderboard(game_account:Pubkey,leaderboard_account:Pubkey,game_auth:Keypair,score:int):
	var player_account_pda:Pubkey = SoarPDA.get_player_pda(SolanaService.wallet.get_pubkey(),get_pid())
	var player_scores_pda:Pubkey = SoarPDA.get_player_scores_pda(player_account_pda,leaderboard_account,get_pid())
	var instructions:Array[Instruction]
	
	#check if player already has a scores account for this leaderboard and if not, add ix of registering them
	#player scores list returns info on player's score on a specific leaderboard. even if it's empty, the account may exists
	var player_scores_list:Dictionary = fetch_player_scores(player_scores_pda,leaderboard_account)
	#for result in player_scores_list["scores"]:
		#print(int(result["score"]))

	if player_scores_list.size()==0:
		var register_player_ix:Instruction = soar_program.build_instruction("registerPlayer",[
		SolanaService.wallet.get_kp(), #payer
		SolanaService.wallet.get_kp(), #user
		player_account_pda, #player PDA
		game_account, #game account 
		leaderboard_account, #leaderboard
		player_scores_pda, #new list of scores pda for the player
		SystemProgram.get_pid() #system program
		],null)
		
		instructions.append(register_player_ix)
		
	var leaderboard_data:Dictionary = fetch_leaderboard_data(leaderboard_account)
	var leaderboard_top_entries_pda:Pubkey = SoarPDA.get_leaderboard_scores_pda(leaderboard_account,get_pid())
	var player_score = AnchorProgram.u64(score * pow(10,leaderboard_data["decimals"]))
	
	var submit_score_ix:Instruction = soar_program.build_instruction("submitScore",[
		SolanaService.wallet.get_kp(), #payer
		game_auth, #authority
		player_account_pda, #player PDA
		game_account, #game account 
		leaderboard_account, #leaderboard 
		player_scores_pda, #player scores PDA
		leaderboard_top_entries_pda, #nleaderboard's score sheet to add the player's score to
		SystemProgram.get_pid() #system program
		],{
			"score":player_score
		})
		
	instructions.append(submit_score_ix)
	SolanaService.transaction_processor.connect("on_transaction_finish",submit_score_to_leaderboard_response)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)
	

func submit_score_to_leaderboard_response(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",submit_score_to_leaderboard_response)
	if transaction_id!="":
		emit_signal("on_score_submitted")
	

