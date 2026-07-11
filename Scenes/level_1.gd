extends Node2D

@onready var crossbow_scene = preload("res://Scenes/crossbow.tscn")

@onready var buttom_layer: TileMapLayer = $ButtomLayer
@onready var player: Node2D = $Player

const TILE_SIZE := 32
const TILE_OFFSET := Vector2(16, 16)
const MOVE_TIME := 0.15

var moving := false
var player_grid_pos = Vector2i.ZERO

var history := [] # Stores snapshots of [downlevel, uplevel, player_grid_pos]

var downlevel = [
	"#XXXXXXXXX",
	"HW0000000X",
	"#X000X000X",
	"#X0100020X",
	"#X0000000X",
	"#X0000000X",
	"#X00000000",
	"#X0000000X",
	"#X0000000X",
	"#XXXXXXXXX",
]

var uplevel = [
	"XXXXXXXXX",
	"W0000000X",
	"X0000000X",
	"X000P000X",
	"X0000000X",
	"X0U000U0X",
	"X00000000",
	"X0000000X",
	"X0000000X",
	"XXXXXXXXX",
]

func _ready() -> void:
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


func _process(_delta):
	if moving:
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
		"L", "R", "U", "D":

			var push_list = []
			var check_tile = target

			# Find all crossbows in a row
			while true:
				var tile = uplevel[check_tile.y][check_tile.x]

				if tile in ["L", "R", "U", "D"]:
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
	
	# Clear old crossbow nodes (we keep the player node, just teleport them)
	for child in get_children():
		if child != player_index_check_or_node(player) and child is Node2D and child != buttom_layer:
			# If it's a crossbow instance, free it
			if child.name.begins_with("crossbow") or "crossbow" in child.scene_file_path:
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

	# Rebuild top layer objects (teleport player, spawn crossbows at right rotations)
	for i in uplevel.size():
		for j in uplevel[i].length():
			match uplevel[i][j]:
				"P":
					player.position = Vector2(j * TILE_SIZE, i * TILE_SIZE) + TILE_OFFSET
				"U": place_crossbow_u(j, i)
				"D": place_crossbow_d(j, i)
				"L": place_crossbow_l(j, i)
				"R": place_crossbow_r(j, i)
