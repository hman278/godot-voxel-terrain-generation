extends Node

# parent node
@onready var world = $world
@onready var player = $player
# used to cull chunks every timeout
@onready var cull_timer = $cull_timer

var noise_texture = FastNoiseLite.new()
var gridmap = preload('res://scenes/gridmap.tscn')

const CHUNK_SIZE = 32
const TERRAIN_SIZE = 512
const TERRAIN_HEIGHT = 7
var chunks: Dictionary = {} # contains the chunk and the origin of its blocks
var chunk_node = null

enum CELL {
	GRASS,
	DIRT,
	BARK_OAK,
	BARK_BIRCH,
	LEAVES_OAK,
	LEAVES_BIRCH,
	GRASS_BLADE_A,
	GRASS_BLADE_B,
	GRASS_BLADE_C,
	FLOWER_RED_A,
	FLOWER_RED_B,
	FLOWER_YELLOW_A,
	FLOWER_YELLOW_B,
}

func _ready():
	# configure
	randomize()
	noise_texture.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_texture.seed = randi()
	
	for i in range(int(-TERRAIN_SIZE/2), int(TERRAIN_SIZE/2), CHUNK_SIZE):
		for j in range(int(-TERRAIN_SIZE/2), int(TERRAIN_SIZE/2), CHUNK_SIZE):
			generate_chunk(Vector3(i, 0, j)) #leave y at 0
	
	cull_timer.connect("timeout", cull_chunks.bind())

# also handles vegetation
func generate_chunk(origin):
	chunk_node = gridmap.instantiate()
	world.add_child(chunk_node)
	chunks[chunk_node] = origin # set origin for each chunk (the actual parent chunk is located at 0,0,0)

	for x in range(origin.x, origin.x + CHUNK_SIZE):
		for z in range(origin.z, origin.z + CHUNK_SIZE):
			var y = int(noise_texture.get_noise_2dv(Vector2(x,z))*TERRAIN_HEIGHT)

			var pos = chunk_node.local_to_map(Vector3(x, y, z))
			chunk_node.set_cell_item(pos, CELL.GRASS, 0)
			
			if y <= -3: 
				chunk_node.set_cell_item(pos, CELL.DIRT, 0)
				continue
			randomize()
			# tree gen
			if int(randf_range(0, 90)) == 2:
				var rand_bark = randi_range(CELL.BARK_OAK, CELL.BARK_BIRCH)
				var rand_leaves = randi_range(CELL.LEAVES_OAK, CELL.LEAVES_BIRCH)
				var bark_len = randi_range(3, 4)
				var leaves_len = randi_range(2, 3)
				var leaves_wid = randi_range(2, 3)
				
				generate_tree(pos, bark_len, leaves_len, leaves_wid, rand_bark, rand_leaves)
			# grass gen
			elif randi_range(0, 1) == 0: 
				chunk_node.set_cell_item(pos + Vector3i(0, 1, 0), randi_range(CELL.GRASS_BLADE_A, CELL.GRASS_BLADE_C), 0)
			# flower gen
			elif randi_range(0, 50) == 0:
				chunk_node.set_cell_item(pos + Vector3i(0, 1, 0), randi_range(CELL.FLOWER_RED_A, CELL.FLOWER_YELLOW_B), 0)

# chunk culling, do better if you can
func cull_chunks():
	if chunks.size() > 0:
		var p = player.global_transform.origin
		for chunk in chunks.keys():
			var c = chunks.get(chunk) # origin
			var distance = p.distance_to(c)

			var direction = p.direction_to(c)
			var dot = direction.dot(-player.global_transform.basis.z)
			
			if dot < 0:
				if distance >= CHUNK_SIZE*2:
					chunk.visible = false
			else:
				chunk.visible = true

func generate_tree(pos: Vector3i, bark_len: int, leaves_len: int, leaves_width: int, bark_type: int, leaves_type: int):
	for i in range(0, bark_len + 1):
		chunk_node.set_cell_item(pos + Vector3i(0, i, 0), bark_type, 0)
	for u in range(bark_len + 1, bark_len + leaves_len + 1):
		for i in range(-leaves_width + 1, leaves_width):
			for j in range(-leaves_width + 1, leaves_width):
				chunk_node.set_cell_item(pos + Vector3i(i, u, j), leaves_type, 0)
	if leaves_width > 1:
		for i in range(-leaves_width + 2, leaves_width - 1):
			for j in range(-leaves_width + 2, leaves_width - 1):
				chunk_node.set_cell_item(pos + Vector3i(i, bark_len + leaves_len + 1, j), leaves_type, 0)
		if leaves_width > 2:
				chunk_node.set_cell_item(pos + Vector3i(0, bark_len + leaves_len + 2, 0), leaves_type, 0)
