extends Spatial


var hit_master_node = preload("res://Hit.tscn")
var miss_master_node = preload("res://Miss.tscn")

func _ready():
	pass 

func _on_WSHandler_ship_hit(boardId, coord, isMiss):
	var my_id = 	$"/root/GameMain/WSHandler".my_id

	
	if boardId == my_id:		
		var scene = hit_master_node
		if isMiss:
			scene = miss_master_node
			
		var i = scene.instance()
		
		add_child(i)
		i.translation.x = coord[0]
		if not isMiss:
			i.translation.y = 0.5
		i.translation.z = coord[1]




