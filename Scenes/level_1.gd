extends Node2D

@onready var buttom_layer: TileMapLayer = $ButtomLayer
@onready var player: Node2D = $Player

const TILE_SIZE := 32
const TILE_OFFSET := Vector2(16, 16)

var level = [
	"000000000",
	"0000P0000",
	"000000000",
	"000000000"
]


func _ready() -> void:
	for y in level.size():
		for x in level[y].length():
			match level[y][x]:
				"0":
					create_grass(x, y)
				"P":
					create_grass(x, y)
					place_player(x, y)


func create_grass(x: int, y: int) -> void:
	buttom_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))


func place_player(x: int, y: int) -> void:
	player.grid_pos = Vector2i(x, y)
	player.position = Vector2(x * TILE_SIZE, y * TILE_SIZE) + TILE_OFFSET
