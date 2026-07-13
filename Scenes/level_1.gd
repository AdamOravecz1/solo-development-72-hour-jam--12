extends Node2D

@onready var crossbow_scene = preload("res://Scenes/crossbow.tscn")
@onready var arrow_scene = preload("res://Scenes/arrow.tscn")
@onready var box_scene = preload("res://Scenes/box.tscn")

@onready var camera: Camera2D = $Camera2D 

@onready var buttom_layer: TileMapLayer = $ButtomLayer
@onready var player: AnimatedSprite2D = $Player
@onready var hunter: AnimatedSprite2D = $Hunter
@onready var ork: AnimatedSprite2D = $Ork

var level = 0

const TILE_SIZE := 32
const TILE_OFFSET := Vector2(16, 16)
const MOVE_TIME := 0.3

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

var downlevel2 = [
	"###XXX#",
	"##XX0X#",
	"##X0WX#",
	"#X000X#",
	"XXX00XX",
	"X00000X",
	"X00000X",
	"X00000X",
	"X00000X",
	"XX000XX",
	"#XXXXX#"
]

var uplevel2 = [
	"###XXX#",
	"##XXOX#",
	"##X0WX#",
	"#XHB0X#",
	"XXX00XX",
	"X0BBBBX",
	"X00000X",
	"XBB0BBX",
	"X0UB00X",
	"XX0P0XX",
	"#XXXXX#"
]

var downlevel3 = [
	"XXXXXXXXX",
	"X0W00000X",
	"XXXXXXX0X",
	"X0X00000X",
	"XWX00000X",
	"X0X34000X",
	"X0000004X",
	"X000000XX",
	"XXXXXXXX#"
]

var uplevel3 = [
	"XXXXXXXXX",
	"XHW0000DX",
	"XXXXXXX0X",
	"XOX00000X",
	"XWXRD000X",
	"X0X000DLX",
	"X0D0U000X",
	"X00P000XX",
	"XXXXXXXX#"
]

var downlevel4 = [
	"##XXXXXXXX",
	"##X0WW100X",
	"XXXXXXWX0X",
	"X002WW100X",
	"X0XWXXXX0X",
	"X001WW0X0X",
	"X0XXXXXX0X",
	"X00000000X",
	"XXXXXXXXXX"
]

var uplevel4 = [
	"##XXXXXXXX",
	"##XHWW0L0X",
	"XXXXXXWXPX",
	"X0R0WW0L0X",
	"X0XWXXXX0X",
	"X0R0WWOX0X",
	"X0XXXXXX0X",
	"X00000000X",
	"XXXXXXXXXX"
]

var downlevel5 = [
	"##XX##",
	"#X00XX",
	"XX000X",
	"X0030X",
	"X0003X",
	"#X000X",
	"##XX0X",
	"#X0W0X",
	"#XXXWX",
	"###X0X",
	"###XXX"
]

var uplevel5 = [
	"##XX##",
	"#X00XX",
	"XXPD0X",
	"X0000X",
	"X0BB0X",
	"#X000X",
	"##XX0X",
	"#XHW0X",
	"#XXXWX",
	"###XOX",
	"###XXX"
]

var downlevel6 = [
	"XXXXXXXXXX",
	"X0W000400X",
	"XX0X00000X",
	"#XWX00000X",
	"#X0000000X",
	"#XXXXXXXXX"
]

var uplevel6 = [
	"XXXXXXXXXX",
	"XHW00U0D0X",
	"XXOX00LU0X",
	"#XWX000BBX",
	"#X00P0000X",
	"#XXXXXXXXX"
]

var downlevel7 = [
	"##XXXXXX",
	"#XX0000X",
	"#X00000X",
	"XX00300X",
	"X0W0030X",
	"XX0X000X",
	"#XXXXXXX"
]

var uplevel7 = [
	"##XXXXXX",
	"#XX0B0PX",
	"#X0DLD0X",
	"XX000B0X",
	"XHW0000X",
	"XXOX0B0X",
	"#XXXXXXX"
]

var downlevel8 = [
	"#XXXXXXX#",
	"#X03W40X#",
	"#X00X00X#",
	"XX00X00XX",
	"X0W0X0W0X",
	"XX00400X#",
	"#X00300X#",
	"#X00000X#",
	"#XXXXXXX#"
]

var uplevel8 = [
	"#XXXXXXX#",
	"#X00W00X#",
	"#X0RXD0X#",
	"XX00X00XX",
	"XHW0X0WOX",
	"XX0U0R0X#",
	"#X00000X#",
	"#X00P00X#",
	"#XXXXXXX#"
]

var levels = [[downlevel0, uplevel0], [downlevel1, uplevel1], [downlevel2, uplevel2], [downlevel3, uplevel3], [downlevel4, uplevel4], [downlevel5, uplevel5], [downlevel6, uplevel6], [downlevel7, uplevel7], [downlevel8, uplevel8]]

var downlevel = []

var uplevel = []

func _ready() -> void:
	downlevel = levels[level][0].duplicate(true)
	uplevel = levels[level][1].duplicate(true)
	center_camera_on_level()
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
				"3": 
					create_temporary_rotater_r(j, i)
				"4": 
					create_temporary_rotater_l(j, i)
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
		
	if Input.is_action_just_pressed("restart"):
		$Hunter.play("default")
		history = []
		downlevel = levels[level][0].duplicate(true)
		uplevel = levels[level][1].duplicate(true)
		print("scevbu")
		clear_current_nodes()
		rebuild_level_instantly()
		return

	var dir := Vector2i.ZERO

	if Input.is_action_just_pressed("right"):
		dir = Vector2i.RIGHT
		player.play("default")
		player.flip_h = false
	elif Input.is_action_just_pressed("left"):
		dir = Vector2i.LEFT
		player.play("default")
		player.flip_h = true
	elif Input.is_action_just_pressed("down"):
		dir = Vector2i.DOWN
		player.play("down")
	elif Input.is_action_just_pressed("up"):
		dir = Vector2i.UP
		player.play("up")

	if dir != Vector2i.ZERO:
		$Sounds/Walk.pitch_scale = randf_range(.8, 1.2)
		$Sounds/Walk.play()
		try_move(dir)


func try_move(dir):
	var target = player_grid_pos + dir

	# Bounds safety checks
	if target.y < 0 or target.y >= downlevel.size(): return
	if target.x < 0 or target.x >= downlevel[target.y].length(): return
		
	var pieces_to_move = []
	var target_positions = []
	var move_type = "walk" # Default state
		
	match uplevel[target.y][target.x]:
		"L", "R", "U", "D", "B":
			var push_list = []
			var check_tile = target

			# Find all consecutive items in the push chain
			while true:
				var tile = uplevel[check_tile.y][check_tile.x]
				if tile in ["L", "R", "U", "D", "B"]:
					push_list.append(check_tile)
					check_tile += dir
				else:
					break

				if check_tile.y < 0 or check_tile.y >= uplevel.size(): return
				if check_tile.x < 0 or check_tile.x >= uplevel[check_tile.y].length(): return

			# If the space behind the chain is blocked, it's an immovable wall/barrier scenario!
			if uplevel[check_tile.y][check_tile.x] != "0" or downlevel[check_tile.y][check_tile.x] == "X" or downlevel[check_tile.y][check_tile.x] == "W":
				# Play blocked/push wall animation in place without moving
				await animate_blocked_push(dir)
				return
				
			# If we successfully get here, the objects CAN move
			move_type = "push"
			save_state()
			
			var p_piece = get_piece_at(player_grid_pos)
			if p_piece:
				pieces_to_move.append(p_piece)
				target_positions.append(Vector2(target * TILE_SIZE) + TILE_OFFSET)
				
			for pos in push_list:
				var cross_piece = get_piece_at(pos)
				if cross_piece:
					pieces_to_move.append(cross_piece)
					target_positions.append(Vector2((pos + dir) * TILE_SIZE) + TILE_OFFSET)

			for i in range(push_list.size() - 1, -1, -1):
				var from = push_list[i]
				var to = from + dir
				uplevel[to.y][to.x] = uplevel[from.y][from.x]
				uplevel[from.y][from.x] = "0"

			uplevel[player_grid_pos.y][player_grid_pos.x] = "0"
			uplevel[target.y][target.x] = "P"
			player_grid_pos = target

		"0":
			# If the upper layer is empty but the bottom floor tile is a wall or water
			if downlevel[target.y][target.x] in ["X", "W"]:
				await animate_blocked_push(dir)
				return
				
			if downlevel[target.y][target.x] in ["0", "1", "2", "3", "4"]:
				save_state()
				var p_piece = get_piece_at(player_grid_pos)
				if p_piece:
					pieces_to_move.append(p_piece)
					target_positions.append(Vector2(target * TILE_SIZE) + TILE_OFFSET)
					
				uplevel[player_grid_pos.y][player_grid_pos.x] = "0"
				uplevel[target.y][target.x] = "P"
				player_grid_pos = target
				
		_: # Catch-all for hitting things like H (Hunter) or O (Ork) directly
			await animate_blocked_push(dir)
			return
		
	var moved_board = uplevel.duplicate(true)

	# (Keep your existing floor rotation loop intact right here...)
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
					"3":
						match tile:
							"U": uplevel[y][x] = "L"
							"L": uplevel[y][x] = "D"
							"D": uplevel[y][x] = "R"
							"R": uplevel[y][x] = "U"
						downlevel[y][x] = "0"
						buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
					"4":
						match tile:
							"U": uplevel[y][x] = "R"
							"R": uplevel[y][x] = "D"
							"D": uplevel[y][x] = "L"
							"L": uplevel[y][x] = "U"
						downlevel[y][x] = "0"
						buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
		
	if pieces_to_move.size() > 0:
		# PASS THE MOVE TYPE HERE
		await animate_board(pieces_to_move, target_positions, dir, move_type)

	if moved_board != uplevel:
		await rotate_board(moved_board, uplevel)
	

		
func animate_board(pieces_to_move: Array, target_positions: Array, dir: Vector2i, move_type: String):
	moving = true
	
	# Play standard walk vs push animation variations
	if move_type == "push":
		if dir == Vector2i.UP:
			player.play("up_push")
		elif dir == Vector2i.DOWN:
			player.play("down_push")
		else:
			player.play("push")
	else: # standard walk
		if dir == Vector2i.UP:
			player.play("up_walk")
		elif dir == Vector2i.DOWN:
			player.play("down_walk")
		else:
			player.play("walk")
	
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

	# Reset cleanly back to matching idle frames
	if dir == Vector2i.UP:
		player.play("up")
	elif dir == Vector2i.DOWN:
		player.play("down")
	else:
		player.play("default")

	moving = false
	
func animate_blocked_push(dir: Vector2i) -> void:
	moving = true
	
	# Play the push animation matching the bumped direction 
	if dir == Vector2i.UP:
		player.play("up_push")
	elif dir == Vector2i.DOWN:
		player.play("down_push")
	else:
		player.play("push")
		
	# Hold the push frame against the solid wall for the same movement time length
	await get_tree().create_timer(MOVE_TIME).timeout
	
	# Return back to looking idle in that direction
	if dir == Vector2i.UP:
		player.play("up")
	elif dir == Vector2i.DOWN:
		player.play("down")
	else:
		player.play("default")
		
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
		# IGNORE THE CAMERA, UI BUTTONS, AND THE TILEMAP LAYER
		if child == camera or child == buttom_layer or child is Button:
			continue
			
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
	
func create_temporary_rotater_r(x: int, y: int) -> void:
	buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(1, 2))
	
func create_temporary_rotater_l(x: int, y: int) -> void:
	buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 3))

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
				"3": create_temporary_rotater_r(j, i)
				"4": create_temporary_rotater_l(j, i)

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
		
	get_piece_at(hunter_pos).play("fire")

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
			$Sounds/Death.play()

			# 1. Animate the arrow into the Ork's tile
			var target_world_pos = Vector2(current_grid_pos * TILE_SIZE) + TILE_OFFSET
			var tween = create_tween()
			tween.tween_property(arrow_node, "position", target_world_pos, 0.15)
			await tween.finished

			# 2. Clear the Ork from the CURRENT level array first
			arrow_node.queue_free()
			uplevel[current_grid_pos.y][current_grid_pos.x] = "0"
			get_piece_at(current_grid_pos).play("dead")
			await get_piece_at(current_grid_pos).animation_finished
			get_piece_at(current_grid_pos).play("default")
			$Hunter.play("default")

			# 3. Now safely progress to the next level map
			level += 1
			if level == 9:
				get_tree().change_scene_to_file("res://Scenes/finished_menu.tscn")
				break
			downlevel = levels[level][0].duplicate(true)
			uplevel = levels[level][1].duplicate(true)
			history = [] # Reset undo history for the clean stage

			# 4. Wipe physical old nodes and draw the new layout
			clear_current_nodes()
			rebuild_level_instantly()
			
			center_camera_on_level()

			hit_something = true
			break
			

		# Check Crossbow Collision (Chain Reaction!)
		if tile_upper in ["L", "R", "U", "D"]:
			$Sounds/CrossBow.play()
			# Animate the arrow physically colliding with the crossbow first
			var target_world_pos = Vector2(current_grid_pos * TILE_SIZE) + TILE_OFFSET
			var tween = create_tween()
			tween.tween_property(arrow_node, "position", target_world_pos, 0.15)
			await tween.finished
			
			# "Deactivate" this crossbow by changing its data representation to lowercase
			# This prevents it from being triggered a second time
			var triggered_crossbow = tile_upper
			uplevel[current_grid_pos.y][current_grid_pos.x] = triggered_crossbow.to_lower()
			get_piece_at(current_grid_pos).play("default")
			await get_tree().create_timer(.2).timeout

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
			tween.tween_property(arrow_node, "position", target_world_pos, 0.15)
			await tween.finished

		# Progress grid calculation along the current active direction
		current_grid_pos += arrow_dir

	# 4. Handle the resolution
	print(outcome)
	
	if arrow_node:
		arrow_node.queue_free()

	arrow_flying = false

func _on_button_pressed() -> void:
	if not arrow_flying:
		$Sounds/Press.play()
		$Sounds/Bow.play()
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
				
				


func center_camera_on_level() -> void:
	if uplevel.size() == 0:
		return
		
	# Total height is the number of rows * TILE_SIZE
	var map_height_pixels = uplevel.size() * TILE_SIZE
	
	# Total width is the number of characters in the first row * TILE_SIZE
	var map_width_pixels = uplevel[0].length() * TILE_SIZE
	
	# The center position is exactly half of the total width and height
	var center_pos = Vector2(map_width_pixels / 2.0, map_height_pixels / 2.0)
	
	camera.position = center_pos


func _on_button_2_pressed() -> void:
	
	get_tree().change_scene_to_file("res://Scenes/menu.tscn")


func _on_button_2_button_down() -> void:
	$Sounds/Press.play()
