extends Control

@onready var main = get_tree().get_first_node_in_group("Main")
@onready var scene = preload("res://Scenes/level_1.tscn")

func choose_level(n):
	var old_scene = get_tree().current_scene

	var new_scene = preload("res://Scenes/level_1.tscn").instantiate()
	new_scene.level = n

	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene

	old_scene.queue_free()

func _ready() -> void:
	print(main)


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/level_1.tscn")

func _on_button_2_pressed() -> void:
	choose_level(1)

func _on_button_3_pressed() -> void:
	choose_level(2)

func _on_button_4_pressed() -> void:
	choose_level(3)


func _on_button_5_pressed() -> void:
	choose_level(4)


func _on_button_6_pressed() -> void:
	choose_level(5)


func _on_button_7_pressed() -> void:
	choose_level(6)


func _on_button_8_pressed() -> void:
	choose_level(7)


func _on_button_9_pressed() -> void:
	choose_level(8)


func _on_button_button_down() -> void:
	$Press.play()


func _on_button_2_button_down() -> void:
	$Press.play()


func _on_button_3_button_down() -> void:
	$Press.play()


func _on_button_4_button_down() -> void:
	$Press.play()


func _on_button_5_button_down() -> void:
	$Press.play()


func _on_button_6_button_down() -> void:
	$Press.play()


func _on_button_7_button_down() -> void:
	$Press.play()


func _on_button_8_button_down() -> void:
	$Press.play()


func _on_button_9_button_down() -> void:
	$Press.play()
