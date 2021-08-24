extends ImmediateGeometry

# this script serves only for debug drawing lines

var begin: Vector3 = Vector3.ZERO
var end: Vector3 = Vector3.ZERO

func draw():
	clear()
	begin(1, null)
	add_vertex(begin)
	add_vertex(end)
	end()
