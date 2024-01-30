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

func get_pid() -> Pubkey:
		return Pubkey.new_from_string(soar_program.get_pid())

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
		
func get_game_data(game_key:Pubkey) -> Dictionary:
	return soar_program.fetch_account("Game",game_key)
	
func add_leaderboard(game_address:String,leaderboard_data:SoarUtils.LeaderboardData) -> void:
	var game_account:Pubkey=Pubkey.new_from_string(game_address)
	var game_data:Dictionary = get_game_data(game_account)
	
	if game_data.size() == 0:
		push_error("Failed to fetch the game data")
		return
		
	var leaderboard_id:int = game_data["leaderboardCount"]+1
	var leaderboard:Pubkey = get_leaderboard_pda(game_account,leaderboard_id)
	var leaderboard_top_entries:Pubkey = get_leaderboard_scores_pda(leaderboard)
	
	var instructions:Array[Instruction]
	var add_leaderboard_ix:Instruction = soar_program.build_instruction("addLeaderboard",[
		SolanaService.wallet.get_kp(), #game authority
		SolanaService.wallet.get_kp(), #payer
		game_account, #game
		leaderboard, #leaderboard PDA
		leaderboard_top_entries, #top entries PDA
		Pubkey.new_from_string("11111111111111111111111111111111") #system program
	],
	leaderboard_data.get_value())
	
	print("Creating Leaderboard with ID: %s"%leaderboard.get_value())
	
	instructions.append(add_leaderboard_ix)
	SolanaService.transaction_processor.connect("on_transaction_finish",register_leaderboard_callback)
	SolanaService.transaction_processor.try_sign_transaction(SolanaService.wallet,instructions)
	
func get_leaderboard_pda(game_account:Pubkey,leaderboard_id:int) -> Pubkey:
	var name_bytes = "leaderboard".to_utf8_buffer()
	var game_bytes = game_account.get_bytes()
	var id_bytes := PackedByteArray()
	id_bytes.resize(8)
	id_bytes.encode_u64(0, leaderboard_id)
	return Pubkey.new_pda_bytes([name_bytes,game_bytes,id_bytes],get_pid())
	
func get_leaderboard_scores_pda(leaderboard_pda:Pubkey) -> Pubkey:
	var name_bytes = "top-scores".to_utf8_buffer()
	var scores_bytes = leaderboard_pda.get_bytes()
	return Pubkey.new_pda_bytes([name_bytes,scores_bytes],get_pid())
	
	
func register_leaderboard_callback(transaction_id:String) -> void:
	SolanaService.transaction_processor.disconnect("on_transaction_finish",register_leaderboard_callback)
	if transaction_id!="":
		emit_signal("on_leaderboard_added")
	
func update_leaderboard() -> void:
	pass
