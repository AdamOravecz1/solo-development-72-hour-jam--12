extends Control

@onready var main = get_tree().get_first_node_in_group("Main")
@onready var scene = preload("res://Scenes/level_1.tscn")

func _ready() -> void:
	print(main)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")




func _on_button_2_pressed() -> void:
	var old_scene = get_tree().current_scene

	var new_scene = preload("res://Scenes/level_1.tscn").instantiate()
	new_scene.level = 1

	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

	old_scene.queue_free()
