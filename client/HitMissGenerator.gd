extends Spatial


var hit_master_node = preload("res://Hit.tscn")
var miss_master_node = preload("res://Miss.tscn")

func _ready():
	pass 

func _on_WSHandler_ship_hit(boardId, coord, isMiss):
	var board_order = 	$"/root/GameMain/WSHandler".board_order

	
	var grid_id = board_order.find(boardId)

	
	if grid_id != -1:
		var new_z = grid_id * 10 + coord[1]
		var new_x = coord[0]
		
		var scene = hit_master_node
		if isMiss:
			scene = miss_master_node
			
		var i = scene.instance()
		
		add_child(i)
		i.translation.x = new_x
		i.translation.z = new_z




