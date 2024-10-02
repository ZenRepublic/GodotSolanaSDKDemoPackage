@tool
extends Node
class_name ShdwDriveCreator

enum StorageSizeUnit {KB,MB,GB}

@export var path_to_keypair:String

@export_category("Create Storage")
@export var storage_name:String
@export var storage_size:int
@export var size_unit:StorageSizeUnit

## Please make sure you have some SOL and $SHDW tokens in your wallet or else you can't create storage!
@export var create: bool:
	set(value):
		if !in_progress:
			create_shdw_storage()
			
@export_category("Upload File to Storage")
@export_file() var file_path:String

## Please make sure you have some SOL and $SHDW tokens in your wallet or else you can't upload a file!
@export var upload: bool:
	set(value):
		if !in_progress:
			upload_to_storage()

		
var in_progress:bool=false

func get_shdw_drive_instance() -> ShdwDrive:
	var shdw_drive:ShdwDrive = ShdwDrive.new()
	add_child(shdw_drive)
	return shdw_drive

func create_shdw_storage() -> void:
	in_progress = true
	print("Creating storage, please wait...")
	
	var owner_keypair:Keypair = Keypair.new_from_file(path_to_keypair)
	if owner_keypair == null:
		print("Failed to parse provided keypair..")
		return
		
	var size:String = str(storage_size)+StorageSizeUnit.keys()[size_unit]
	
	var shdw_drive:ShdwDrive = get_shdw_drive_instance()
	shdw_drive.create_storage_account(owner_keypair,storage_name,size)
	var result:Dictionary = await shdw_drive.storage_account_response
	shdw_drive.queue_free()
	in_progress = false
	
	print(result)
	
func upload_to_storage() -> void:
	in_progress = true
	print("Uploading file to storage, please wait...")
	
	var owner_keypair:Keypair = Keypair.new_from_file(path_to_keypair)
	if owner_keypair == null:
		print("Failed to parse provided keypair..")
		return
	
	var shdw_drive:ShdwDrive = get_shdw_drive_instance()
	var storage_account = shdw_drive.new_storage_account_pubkey(owner_keypair,0)
	shdw_drive.upload_file_to_storage(file_path,owner_keypair,storage_account)
	var result:Dictionary = await shdw_drive.upload_response
	shdw_drive.queue_free()
	in_progress = false
	
	

	
	
