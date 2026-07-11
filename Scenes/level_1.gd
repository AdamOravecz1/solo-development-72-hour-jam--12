extends Node2D

@onready var crossbow_scene = preload("res://Scenes/crossbow.tscn")
@onready var arrow_scene = preload("res://Scenes/arrow.tscn")
@onready var box_scene = preload("res://Scenes/box.tscn")


@onready var buttom_layer: TileMapLayer = $ButtomLayer
@onready var player: Node2D = $Player
@onready var hunter: AnimatedSprite2D = $Hunter
@onready var ork: AnimatedSprite2D = $Ork

var level = 0

const TILE_SIZE := 32
const TILE_OFFSET := Vector2(16, 16)
const MOVE_TIME := 0.15

var moving := false
var arrow_flying := false
var player_grid_pos = Vector2i.ZERO

var history := [] # Stores snapshots of [downlevel, uplevel, player_grid_pos]

var downlevel0 = [
	"XXXXXXXXX",
	"X0W00000X",
	"XXX002XWX",
	"##X000X0X",
	"##X000X0X",
	"##X000X0X",
	"##XXXXXXX"
]

var uplevel0 = [
	"XXXXXXXXX",
	"XHW00000X",
	"XXX000XWX",
	"##X0L0X0X",
	"##X000X0X",
	"##XP00XOX",
	"##XXXXXXX"
]

var downlevel1 = [
	"#XXXXXXXXXXX",
	"XX000000000X",
	"X0W00000000X",
	"XX0X0000000X",
	"#X0X0000000X",
	"#X0X0000000X",
	"#XWX0000000X",
	"#X000000001X",
	"#X000000000X",
	"#XXXXXXXXXXX",
]

var uplevel1 = [
	"#XXXXXXXXXXX",
	"XX000000000X",
	"XHW000000DUX",
	"XXOX0000000X",
	"#X0X00P0000X",
	"#X0X0U00000X",
	"#XWX0000000X",
	"#X00B000000X",
	"#X00B000000X",
	"#XXXXXXXXXXX",
]

var levels = [[downlevel0, uplevel0], [downlevel1, uplevel1]]

var downlevel = []

var uplevel = []

func _ready() -> void:
	downlevel = levels[level][0]
	uplevel = levels[level][1]
	for i in downlevel.size():
		for j in downlevel[i].length():
			match downlevel[i][j]:
				"0":
					create_grass(j, i)
				"X":
					create_wall(j, i)
				"W":
					create_water(j, i)
				"1":
					create_rotater_r(j, i)
				"2":
					create_rotater_l(j, i)
	for i in uplevel.size():
		for j in uplevel[i].length():
			match uplevel[i][j]:
				"P":
					place_player(j, i)
				"U":
					place_crossbow_u(j, i)
				"D":
					place_crossbow_d(j, i)
				"L":
					place_crossbow_l(j, i)
				"R":
					place_crossbow_r(j, i)
				"H":
					place_hunter(j, i)
				"O":
					place_ork(j, i)
				"B":
					place_box(j, i)


func _process(_delta):
	if moving or arrow_flying:
			return

	# Check for undo first
	if Input.is_action_just_pressed("undo"):
		undo_move()
		return

	var dir := Vector2i.ZERO

	if Input.is_action_just_pressed("right"):
		dir = Vector2i.RIGHT
	elif Input.is_action_just_pressed("left"):
		dir = Vector2i.LEFT
	elif Input.is_action_just_pressed("down"):
		dir = Vector2i.DOWN
	elif Input.is_action_just_pressed("up"):
		dir = Vector2i.UP

	if dir != Vector2i.ZERO:
		try_move(dir)


func try_move(dir):
	var old_board = uplevel.duplicate(true)
	var target = player_grid_pos + dir

	if target.y < 0 or target.y >= downlevel.size():
		return
	if target.x < 0 or target.x >= downlevel[target.y].length():
		return
		
	var pieces_to_move = []
	var target_positions = []
		
	match uplevel[target.y][target.x]:
		"L", "R", "U", "D", "B":

			var push_list = []
			var check_tile = target

			# Find all crossbows in a row
			while true:
				var tile = uplevel[check_tile.y][check_tile.x]

				if tile in ["L", "R", "U", "D", "B"]:
					push_list.append(check_tile)
					check_tile += dir
				else:
					break

				# Out of bounds
				if check_tile.y < 0 or check_tile.y >= uplevel.size():
					return
				if check_tile.x < 0 or check_tile.x >= uplevel[check_tile.y].length():
					return

			# The tile after the last crossbow must be empty and walkable
			if uplevel[check_tile.y][check_tile.x] != "0" or downlevel[check_tile.y][check_tile.x] == "X" or downlevel[check_tile.y][check_tile.x] == "W":
				return
			save_state()
			# COLLECT PIECES FOR ANIMATION BEFORE MOVING THEM IN DATA
			var p_piece = get_piece_at(player_grid_pos)
			if p_piece:
				pieces_to_move.append(p_piece)
				target_positions.append(Vector2(target * TILE_SIZE) + TILE_OFFSET)
				
			for pos in push_list:
				var cross_piece = get_piece_at(pos)
				if cross_piece:
					pieces_to_move.append(cross_piece)
					target_positions.append(Vector2((pos + dir) * TILE_SIZE) + TILE_OFFSET)

			# Move crossbows from back to front in the array
			for i in range(push_list.size() - 1, -1, -1):
				var from = push_list[i]
				var to = from + dir

				uplevel[to.y][to.x] = uplevel[from.y][from.x]
				uplevel[from.y][from.x] = "0"

			# Move player in the array
			uplevel[player_grid_pos.y][player_grid_pos.x] = "0"
			uplevel[target.y][target.x] = "P"
			player_grid_pos = target

		"0":
			if downlevel[target.y][target.x] in ["0", "1", "2"]:
				save_state()
				# COLLECT PLAYER FOR ANIMATION
				var p_piece = get_piece_at(player_grid_pos)
				if p_piece:
					pieces_to_move.append(p_piece)
					target_positions.append(Vector2(target * TILE_SIZE) + TILE_OFFSET)
					
				uplevel[player_grid_pos.y][player_grid_pos.x] = "0"
				uplevel[target.y][target.x] = "P"
				player_grid_pos = target
				
		
	var moved_board = uplevel.duplicate(true)

	# rotate crossbows depending on floor tile
	for y in uplevel.size():
		for x in uplevel[y].length():
			var tile = uplevel[y][x]

			if tile in ["U", "D", "L", "R"]:
				match downlevel[y][x]:
					"1":
						match tile:
							"U": uplevel[y][x] = "R"
							"R": uplevel[y][x] = "D"
							"D": uplevel[y][x] = "L"
							"L": uplevel[y][x] = "U"
					"2":
						match tile:
							"U": uplevel[y][x] = "L"
							"L": uplevel[y][x] = "D"
							"D": uplevel[y][x] = "R"
							"R": uplevel[y][x] = "U"
	
	print()
	for i in uplevel:
		print(i)
		
	# Pass our pre-collected pieces straight to the animation function
	if pieces_to_move.size() > 0:
		await animate_board(pieces_to_move, target_positions)

	# Animate rotations after movement
	if moved_board != uplevel:
		await rotate_board(moved_board, uplevel)
	

		
func animate_board(pieces_to_move: Array, target_positions: Array):
	moving = true
	
	var tween = create_tween()
	var tween_count = 0

	for i in pieces_to_move.size():
		var piece = pieces_to_move[i]
		var target_pos = target_positions[i]
		
		tween.parallel().tween_property(
			piece,
			"position",
			target_pos,
			MOVE_TIME
		)
		tween_count += 1

	if tween_count > 0:
		await tween.finished

	moving = false
	
func rotate_board(old_board, new_board):
	var tween = create_tween()
	var tween_count = 0

	for y in old_board.size():
		for x in old_board[y].length():

			var old_tile = old_board[y][x]
			var new_tile = new_board[y][x]

			# Crossbow stayed in the same place but changed direction
			if old_tile in ["U", "D", "L", "R"] and new_tile in ["U", "D", "L", "R"]:
				
				if old_tile != new_tile:
					var piece = get_piece_at(Vector2i(x, y))
					print(piece)

					if piece:
						var rotation_change = 0.0

						match old_tile + new_tile:
							# clockwise
							"UR", "RD", "DL", "LU":
								rotation_change = PI / 2

							# counterclockwise
							"UL", "LD", "DR", "RU":
								rotation_change = -PI / 2


						tween.parallel().tween_property(
							piece,
							"rotation",
							piece.rotation + rotation_change,
							MOVE_TIME
						)

						tween_count += 1

	if tween_count > 0:
		await tween.finished
	
func get_piece_at(grid_pos: Vector2i) -> Node2D:
	var world_pos = Vector2(grid_pos * TILE_SIZE) + TILE_OFFSET

	for child in get_children():
		if child is Node2D and child.position.distance_to(world_pos) < 0.1:
			return child

	return null
	
func create_grass(x: int, y: int) -> void:
	buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

func create_wall(x: int, y: int) -> void:
	buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 1))
	
func create_water(x: int, y: int) -> void:
	buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 0))
	
func create_rotater_r(x: int, y: int) -> void:
	buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 2))
	
func create_rotater_l(x: int, y: int) -> void:
	buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 1))

func place_player(x: int, y: int) -> void:
	player_grid_pos = Vector2i(x, y)
	player.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + TILE_OFFSET
	
func place_hunter(x: int, y: int) -> void:
	hunter.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + TILE_OFFSET
	
func place_ork(x: int, y: int) -> void:
	ork.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + TILE_OFFSET
	
func place_crossbow_u(x: int, y: int) -> void:
	var crossbow = crossbow_scene.instantiate()
	add_child(crossbow)
	crossbow.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + TILE_OFFSET
	
func place_crossbow_d(x: int, y: int) -> void:
	var crossbow = crossbow_scene.instantiate()
	add_child(crossbow)
	crossbow.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + TILE_OFFSET
	crossbow.rotation = PI
	
func place_crossbow_r(x: int, y: int) -> void:
	var crossbow = crossbow_scene.instantiate()
	add_child(crossbow)
	crossbow.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + TILE_OFFSET
	crossbow.rotation = PI/2
	
func place_crossbow_l(x: int, y: int) -> void:
	var crossbow = crossbow_scene.instantiate()
	add_child(crossbow)
	crossbow.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + TILE_OFFSET
	crossbow.rotation = 2*PI/4*3
	
func place_box(x: int, y: int) -> void:
	var box = box_scene.instantiate()
	add_child(box)
	box.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + TILE_OFFSET

	
func save_state() -> void:
	# Deep copy the arrays so changes don't bleed into history
	var downlevel_copy = downlevel.duplicate(true)
	var uplevel_copy = uplevel.duplicate(true)
	history.append([downlevel_copy, uplevel_copy, player_grid_pos])

func undo_move() -> void:
	if history.size() == 0:
		print("Already at the beginning!")
		return
		
	# Pop the last saved state
	var previous_state = history.pop_back()
	
	downlevel = previous_state[0]
	uplevel = previous_state[1]
	player_grid_pos = previous_state[2]
	
	# Clear out the physical nodes on screen to rebuild them instantly
	# Clear TileMapLayer cells
	buttom_layer.clear()
	for y in range(-50, 50):
		for x in range(-50, 50):
			buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	
# Clear old crossbow and box nodes
	for child in get_children():
		if child != player_index_check_or_node(player) and child is Node2D and child != buttom_layer:
			# Check if it's a crossbow or a box scene instance, then free it
			if child.name.begins_with("crossbow") or "crossbow" in child.scene_file_path or \
			   child.name.begins_with("box") or "box" in child.scene_file_path:
				child.queue_free()
				
	# Rebuild the level visually based on the restored arrays
	rebuild_level_instantly()

# Quick safety check helper to ensure we don't delete the player node
func player_index_check_or_node(p_node: Node2D) -> Node2D:
	return p_node

func rebuild_level_instantly() -> void:
	# Rebuild bottom layer floor
	for i in downlevel.size():
		for j in downlevel[i].length():
			match downlevel[i][j]:
				"0": create_grass(j, i)
				"X": create_wall(j, i)
				"W": create_water(j, i)
				"1": create_rotater_r(j, i)
				"2": create_rotater_l(j, i)

	# Rebuild top layer objects
	for i in uplevel.size():
		for j in uplevel[i].length():
			match uplevel[i][j]:
				"P": place_player(j, i)
				"H": place_hunter(j, i)
				"O": place_ork(j, i)
				"U", "u": place_crossbow_u(j, i)
				"D", "d": place_crossbow_d(j, i)
				"L", "l": place_crossbow_l(j, i)
				"R", "r": place_crossbow_r(j, i)
				"B": place_box(j, i) 

func fire_arrow_right() -> void:
	var hunter_pos := Vector2i(-1, -1)
	
	# 1. Find the Hunter ('H') on the board
	for y in uplevel.size():
		for x in uplevel[y].length():
			if uplevel[y][x] == "H":
				hunter_pos = Vector2i(x, y)
				break
		if hunter_pos != Vector2i(-1, -1):
			break
			
	if hunter_pos == Vector2i(-1, -1):
		print("No hunter found on the level!")
		return

	# Lock the game state and save history for undoing
	arrow_flying = true
	save_state()

	# 2. Spawn a visual arrow instance at the hunter's position
	var arrow_node = arrow_scene.instantiate() 
	add_child(arrow_node)
	arrow_node.position = Vector2(hunter_pos * TILE_SIZE) + TILE_OFFSET

	# 3. Dynamic arrow tracking (Direction can change!)
	var current_grid_pos = hunter_pos + Vector2i.RIGHT
	var arrow_dir = Vector2i.RIGHT # Starts by flying right
	var hit_something := false
	var outcome := ""

	while not hit_something:
		# Check map boundaries
		if current_grid_pos.y < 0 or current_grid_pos.y >= uplevel.size() or \
		   current_grid_pos.x < 0 or current_grid_pos.x >= uplevel[current_grid_pos.y].length():
			outcome = "lose - Arrow went offscreen"
			hit_something = true
			break
			
		var tile_upper = uplevel[current_grid_pos.y][current_grid_pos.x]
		var tile_lower = downlevel[current_grid_pos.y][current_grid_pos.x]
		
		# Check Wall Collision (Downlevel 'X')

		if tile_lower == "X" or tile_upper == "B":
			outcome = "lose - Arrow hit a barrier"
			hit_something = true
			break

		# Check Ork Collision (Uplevel 'O')
		if tile_upper == "O":
			outcome = "win - Arrow hit the Ork!"
			level += 1
			downlevel = levels[level][0]
			uplevel = levels[level][1]
			history = []
			clear_current_nodes()
			
			rebuild_level_instantly()
			
			uplevel[current_grid_pos.y][current_grid_pos.x] = "0"
			hit_something = true
			
			var target_world_pos = Vector2(current_grid_pos * TILE_SIZE) + TILE_OFFSET
			var tween = create_tween()
			tween.tween_property(arrow_node, "position", target_world_pos, MOVE_TIME)
			await tween.finished
			break
			

		# Check Crossbow Collision (Chain Reaction!)
		if tile_upper in ["L", "R", "U", "D"]:
			# Animate the arrow physically colliding with the crossbow first
			var target_world_pos = Vector2(current_grid_pos * TILE_SIZE) + TILE_OFFSET
			var tween = create_tween()
			tween.tween_property(arrow_node, "position", target_world_pos, MOVE_TIME)
			await tween.finished
			
			# "Deactivate" this crossbow by changing its data representation to lowercase
			# This prevents it from being triggered a second time
			var triggered_crossbow = tile_upper
			uplevel[current_grid_pos.y][current_grid_pos.x] = triggered_crossbow.to_lower()

			# Determine the new direction based on the crossbow type
			match triggered_crossbow:
				"U": 
					arrow_dir = Vector2i.UP
					arrow_node.rotation = -PI / 2
				"D": 
					arrow_dir = Vector2i.DOWN
					arrow_node.rotation = PI / 2
				"L": 
					arrow_dir = Vector2i.LEFT
					arrow_node.rotation = PI
				"R": 
					arrow_dir = Vector2i.RIGHT
					arrow_node.rotation = 0.0

			print("Arrow redirected by Crossbow ", triggered_crossbow, " and deactivated.")
			
			# Step out of the crossbow's tile in its new firing direction
			current_grid_pos += arrow_dir
			continue # Jump to the next iteration of the loop

		# If the tile is completely empty, animate through it smoothly
		if tile_upper == "0":
			var target_world_pos = Vector2(current_grid_pos * TILE_SIZE) + TILE_OFFSET
			var tween = create_tween()
			tween.tween_property(arrow_node, "position", target_world_pos, MOVE_TIME)
			await tween.finished

		# Progress grid calculation along the current active direction
		current_grid_pos += arrow_dir

	# 4. Handle the resolution
	print(outcome)
	
	arrow_node.queue_free()

	arrow_flying = false

func _on_button_pressed() -> void:
	if not arrow_flying:
		fire_arrow_right()
	
func clear_current_nodes() -> void:
	# 1. Clear TileMapLayer cells
	buttom_layer.clear()
	for y in range(-50, 50):
		for x in range(-50, 50):
			buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	
	# 2. Clear old spawned nodes (keeping persistent actors)
	for child in get_children():
		if child is Node2D and child != buttom_layer and child != player and child != hunter and child != ork:
			# Check if it's a crossbow or a box scene instance, then free it
			if child.name.begins_with("crossbow") or "crossbow" in child.scene_file_path or \
			   child.name.begins_with("box") or "box" in child.scene_file_path:
				child.queue_free()
