extends Node2D

@onready var crossbow_scene = preload("res://Scenes/crossbow.tscn")

@onready var buttom_layer: TileMapLayer = $ButtomLayer
@onready var player: Node2D = $Player

const TILE_SIZE := 32
const TILE_OFFSET := Vector2(16, 16)
const MOVE_TIME := 0.15

var moving := false
var player_grid_pos = Vector2i.ZERO

var downlevel = [
	"000000000",
	"000000000",
	"000000000",
	"000000000"
]

var uplevel = [
	"000000000",
	"0000P0000",
	"00L000R00",
	"000000000"
]

func _ready() -> void:
	for i in downlevel.size():
		for j in downlevel[i].length():
			match downlevel[i][j]:
				"0":
					create_grass(j, i)
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
		
	match uplevel[target.y][target.x]:
		"L", "R", "U", "D":
			var next_tile = target + dir
			if next_tile.y < 0 or next_tile.y >= downlevel.size():
				return
			if next_tile.x < 0 or next_tile.x >= downlevel[target.y].length():
				return
			if uplevel[next_tile.y][next_tile.x] == "0" and downlevel[next_tile.y][next_tile.x] == "0":
				uplevel[next_tile.y][next_tile.x] = uplevel[target.y][target.x]
				uplevel[player_grid_pos.y][player_grid_pos.x] = "0"
				uplevel[target.y][target.x] = "P"
				player_grid_pos = target

		"0":
			uplevel[player_grid_pos.y][player_grid_pos.x] = "0"
			uplevel[target.y][target.x] = "P"
			player_grid_pos = target
	
	print()
	for i in uplevel:
		print(i)
	
	if old_board != uplevel:
		animate_board(old_board, uplevel)
		
func animate_board(old_board, new_board):
	moving = true
	
	var tween = create_tween()

	for y in old_board.size():
		for x in old_board[y].length():

			var old_tile = old_board[y][x]

			# A piece moved away from this position
			if old_tile != "0":
				var new_position = Vector2i(-1, -1)

				# Find where this same piece went
				for ny in new_board.size():
					for nx in new_board[ny].length():
						if new_board[ny][nx] == old_tile:
							# avoid matching the same unchanged tile
							if nx != x or ny != y:
								new_position = Vector2i(nx, ny)
								break

					if new_position != Vector2i(-1, -1):
						break

				if new_position != Vector2i(-1, -1):
					var piece = get_piece_at(Vector2i(x, y))

					if piece:
						var target_pos = Vector2(new_position * TILE_SIZE) + TILE_OFFSET

						tween.parallel().tween_property(
							piece,
							"position",
							target_pos,
							MOVE_TIME
						)

	await tween.finished
	moving = false
	
func get_piece_at(grid_pos: Vector2i) -> Node2D:
	var world_pos = Vector2(grid_pos * TILE_SIZE) + TILE_OFFSET

	for child in get_children():
		if child is Node2D and child.position.distance_to(world_pos) < 0.1:
			return child

	return null
	
func create_grass(x: int, y: int) -> void:
	buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))


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
