extends MeshInstance

signal cursor_select(gridNum, x, y)

func _ready():
	visible = false

func _input(event):
	if visible:
		if event.is_action_pressed("ui_up"):
			translation.x += 1
		if event.is_action_pressed("ui_down"):
			translation.x -= 1
		if event.is_action_pressed("ui_right"):
			translation.z += 1
		if event.is_action_pressed("ui_left"):
			translation.z -= 1

		translation.x = clamp(translation.x, 0, 7)
		translation.z = clamp(translation.z, 0, 27)

		if translation.z == 8 or translation.z == 18:
			translation.z += 2
		if translation.z == 9 or translation.z == 19:
			translation.z -= 2


		if event.is_action_pressed("ui_accept"):
			emit_signal("cursor_select", floor(translation.z/10), translation.x, fmod(translation.z, 10))
			visible = false


func _on_WSHandler_start_playing():
	visible = true

func _on_WSHandler_new_round():
	visible = true
