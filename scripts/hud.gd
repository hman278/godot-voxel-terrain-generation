extends Control

onready var text = $debug_text
onready var player = get_parent()

func _process(delta):
	# display debug information
	var fps = str(Performance.get_monitor(Performance.TIME_FPS))
	var obj_count = str(Performance.get_monitor(Performance.OBJECT_COUNT))
	var obj_in_frame = str(Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME))
	var draw_calls = str(Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME))
	var dynamic_mem = str(Performance.get_monitor(Performance.MEMORY_DYNAMIC)/1000000) + 'mb'
	var static_mem = str(Performance.get_monitor(Performance.MEMORY_STATIC)/1000000) + 'mb'
	var coords = str(player.global_transform.origin)
	text.text = 'fps: ' + fps + '\nobject count: ' + obj_count + '\nobjects in frame: ' + obj_in_frame + '\ndrawcalls: ' + draw_calls + '\ndynamic memory: ' + dynamic_mem + '\nstatic memory: ' + static_mem + '\nposition: ' + coords
