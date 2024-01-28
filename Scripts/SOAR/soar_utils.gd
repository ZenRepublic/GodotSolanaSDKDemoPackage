extends Node
class_name SoarUtils

class GameAttributes:
	var title:String
	var description:String
	var genre = AnchorProgram.u8(0)
	var game_type = AnchorProgram.u8(0)
	var nft_meta:Pubkey
	
	func get_value() -> Dictionary:
		var dict:Dictionary={
			"title":title,
			"description":description,
			"genre":genre,
			"game_type":game_type,
			"nft_meta":nft_meta
		}
		return dict
		
	func set_genre(value:int) -> void:
		genre = AnchorProgram.u8(value)

	func set_game_type(value:int) -> void:
		game_type = AnchorProgram.u8(value)
