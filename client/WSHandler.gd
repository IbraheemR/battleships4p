extends Node

export var websocket_url = "ws://bs4.ibraheemrodrigues.com:24725"

var _client = WebSocketClient.new()

var game_state = null

var ingame_ids = null
var board_order = null
var my_id = null


signal network_error
signal set_id(id)
signal start_placement(ids)
signal start_playing
signal ship_hit(boardId, coord, isMiss)
signal new_round
signal end_game(win)

signal send_msg(type, data)


func _ready():
	# Connect base signals to get notified of connection open, close, and errors.
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	# This signal is emitted when not using the Multiplayer API every time
	# a full packet is received.
	# Alternatively, you could check get_peer(1).get_available_packets() in a loop.
	_client.connect("data_received", self, "_on_data")

func _input(event):
	if event.is_action_pressed("ui_accept") and game_state == null:
		print("ee")
		var err = _client.connect_to_url(websocket_url)
		if err != OK:
			emit_signal("network_error")
			print("Unable to connect")
			set_process(false)
		else:
			game_state = "queue"
		
func _closed(was_clean = false):
	print("Closed, clean: ", was_clean)
	set_process(false)
	emit_signal("network_error")
	
func _connected(_proto = ""):
		
	print("Connected!")
	_client.get_peer(1).put_packet('{"type":"ready"}'.to_utf8())

func _on_data():
	var msg = _client.get_peer(1).get_packet().get_string_from_utf8()
	var info = JSON.parse(msg).result
	var data  = null
	if info.has("data"):
		data = info["data"]
	var type = info["type"]

	print(type, "->", data)

	if type == "id":
		emit_signal("set_id", data)
		my_id = data
		get_parent().get_node("Label").text = data

	elif type == "start_placement":
		emit_signal("start_placement", data)
		game_state = "placement"
		ingame_ids = data
		board_order = ingame_ids.duplicate()
		board_order.sort()
		board_order.erase(my_id)

	elif type == "start_playing":
		emit_signal("start_playing")
		game_state = "playing"


	elif type == "ship_hit":
		emit_signal("ship_hit", data["boardId"], data["coord"], data["miss"])

	elif type == "new_round":
		emit_signal("new_round")

	elif type == "win":
		emit_signal("end_game", data == my_id)
		game_state = "win"

func _process(_delta):
	_client.poll()

func send_msg(type, data):
	var msg = {
		"type": type,
		"data": data
	}

	msg = JSON.print(msg).to_utf8()
	_client.get_peer(1).put_packet(msg)

	emit_signal("send_msg", type, data)

func _on_Cursor_cursor_select(gridNum, x, y):
	send_msg("shot", {"coord": [x, y], "boardId": board_order[gridNum]})
	print(gridNum, "-", board_order, "-", board_order[gridNum])
