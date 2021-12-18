extends KinematicBody

export(NodePath) var waiting_node
export(NodePath) var network_error_node
export(NodePath) var home_grid
export(NodePath) var foreign_grids
export(NodePath) var win_text
export(NodePath) var lose_text

var target = null


func _physics_process(_delta):
	if target:
		var target_t = get_node(target).global_transform.origin
		translation = (3 * translation + target_t)/4
	
#---
var my_id 

func _on_WSHandler_set_id(id):
	my_id = id
	target = waiting_node

func _on_WSHandler_network_error():
	target = network_error_node

func _on_WSHandler_start_placement(_ids):
	target = home_grid

func _on_WSHandler_start_playing():
	target = foreign_grids

func _on_WSHandler_new_round():
	target = foreign_grids

func _on_WSHandler_send_msg(type, _data):
	if type == "placements" or type == "shot":
		target = waiting_node


func _on_WSHandler_end_game(win):
	if win:
		target = win_text
	else:
		target = lose_text
