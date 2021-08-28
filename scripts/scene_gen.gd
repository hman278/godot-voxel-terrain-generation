extends Node

# this is what the world is generated under
onready var world = $world
onready var player = $player
# used to cull chunks every timeout
onready var cull_timer = $cull_timer
# animation player used to change time of day
onready var light_animp = $directional_light/animation_player

var noise = OpenSimplexNoise.new()
var gridmap = preload('res://scenes/gridmap.tscn')
var env = preload('res://default_env.tres') 

const CHUNK_SIZE = 64
const TERRAIN_SIZE = 512
const TERRAIN_HEIGHT = 15
var chunks: Dictionary = {} # contains the chunk and the origin of its blocks

func _ready():
	# configure
	randomize()
	noise.seed = randi()
	noise.octaves = 2
	noise.period = 32
	noise.persistence = 0.5
	noise.lacunarity = 1
	
	for i in range(int(-TERRAIN_SIZE/2), int(TERRAIN_SIZE/2), CHUNK_SIZE):
		for j in range(int(-TERRAIN_SIZE/2), int(TERRAIN_SIZE/2), CHUNK_SIZE):
			generate_chunk(Vector3(i, 0, j)) #leave y at 0
	
	cull_timer.connect('timeout', self, 'cull_chunks')
	# change the values in this animation player to 
	# get day length matching your needs
	light_animp.play('day_night_cycle')

# also handles vegetation
func generate_chunk(origin):
	var chunk_node = gridmap.instance()
	world.add_child(chunk_node)
	chunks[chunk_node] = origin # set origin for each chunk (the actual parent chunk is located at 0,0,0)

	for x in range(origin.x, origin.x + CHUNK_SIZE):
		for z in range(origin.z, origin.z + CHUNK_SIZE):
			var y = int(noise.get_noise_2dv(Vector2(x,z))*TERRAIN_HEIGHT)

			var pos = chunk_node.world_to_map(Vector3(x, y, z))
			chunk_node.set_cell_item(pos.x, pos.y, pos.z, 0, 0)
			
			# tree generation, you can add more tree types here
			randomize()
			if int(rand_range(0, 150)) == 2:
				for i in 3:
					chunk_node.set_cell_item(pos.x, pos.y+i, pos.z, 1, 0)
				for u in range(3, 7):
					for i in range(-2, 3):
						for j in range(-2, 3):
							chunk_node.set_cell_item(pos.x+i, pos.y+u, pos.z+j, 0, 0)
				for i in range(-1, 2):
					for j in range(-1, 2):
						chunk_node.set_cell_item(pos.x+i, pos.y+7, pos.z+j, 0, 0)
				chunk_node.set_cell_item(pos.x, pos.y+8, pos.z, 0, 0)

# chunk culling
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
