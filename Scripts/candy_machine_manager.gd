extends Node
class_name CandyMachineManager

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func fetch_candy_machine(cm_id:Pubkey) -> CandyMachineData:
	return MplCandyMachine.get_candy_machine_info(cm_id)
