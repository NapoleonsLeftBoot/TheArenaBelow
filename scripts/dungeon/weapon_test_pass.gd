extends Node

@export var fight_scene: PackedScene
@export var selected_weapon: WeaponTypes.Type = WeaponTypes.Type.FISTS

func start_fight() -> void:
	#inantiates fight scene
	var fight = fight_scene.instantiate()
	
	#Grabs the player from the fight scene
	var player = fight.get_node("Player") as Player
	
	#sets player weapon to the selected weapon
	#you can either set it up top or in the inspector tab
	player.set_weapon(selected_weapon)
	
	#adds the fight scene to the same directory level as this scene
	get_tree().root.add_child(fight)
	
	#gets rid of this scene to free up space n stuff
	get_tree().current_scene.queue_free()
	
	#makes the fight scene the main scene
	#so we basically replaces whatever was here with the fight scene
	get_tree().current_scene = fight

func _input(event: InputEvent) -> void:
	#waits till player presses enter to do the function above
	if event.is_action_pressed("ui_accept"):
		start_fight()
