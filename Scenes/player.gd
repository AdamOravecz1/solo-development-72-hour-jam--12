extends Node2D

const TILE_SIZE := 32
const TILE_OFFSET := Vector2(16, 16)
const MOVE_TIME := 0.15

var grid_pos := Vector2i.ZERO
var moving := false

@onready var level = $".."


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


func try_move(dir: Vector2i):
	print(level.level)
	var target := grid_pos + dir

	# check array bounds
	if target.y < 0 or target.y >= level.level.size():
		return

	if target.x < 0 or target.x >= level.level[target.y].length():
		return

	# check what's in the array
	var tile = level.level[target.y][target.x]
	print(tile)

	if tile == "0":
		move_to(target)

	elif tile == "B":
		# later: push box logic here
		pass

	elif tile == "#":
		return


func move_to(target: Vector2i):
	# remove old player position
	level.level[grid_pos.y][grid_pos.x] = "0"

	# put player in new position
	level.level[target.y][target.x] = "P"

	grid_pos = target
	moving = true

	var tween = create_tween()
	tween.tween_property(
		self,
		"position",
		Vector2(grid_pos * TILE_SIZE) + TILE_OFFSET,
		MOVE_TIME
	)

	await tween.finished
	moving = false
