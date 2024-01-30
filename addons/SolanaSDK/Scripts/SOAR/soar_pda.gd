extends Node
class_name SoarPDA

static func get_leaderboard_pda(game_account:Pubkey,leaderboard_id:int, pid:Pubkey) -> Pubkey:
	var name_bytes = "leaderboard".to_utf8_buffer()
	var game_bytes = game_account.get_bytes()
	var id_bytes := PackedByteArray()
	id_bytes.resize(8)
	id_bytes.encode_u64(0, leaderboard_id)
	return Pubkey.new_pda_bytes([name_bytes,game_bytes,id_bytes],pid)
	
	
static func get_leaderboard_scores_pda(leaderboard_pda:Pubkey, pid:Pubkey) -> Pubkey:
	var name_bytes = "top-scores".to_utf8_buffer()
	var scores_bytes = leaderboard_pda.get_bytes()
	return Pubkey.new_pda_bytes([name_bytes,scores_bytes],pid)
	
	
static func get_player_pda(user_key:Pubkey, pid:Pubkey) -> Pubkey:
	var name_bytes = "player".to_utf8_buffer()
	var user_bytes = user_key.get_bytes()
	return Pubkey.new_pda_bytes([name_bytes,user_bytes],pid)
	
static func get_player_scores_pda(user_key:Pubkey,leaderboard_id:Pubkey, pid:Pubkey) -> Pubkey:
	var name_bytes = "player-scores-list".to_utf8_buffer()
	var user_bytes = user_key.get_bytes()
	var leaderboard_bytes = leaderboard_id.get_bytes()
	return Pubkey.new_pda_bytes([name_bytes,user_bytes,leaderboard_bytes],pid)

