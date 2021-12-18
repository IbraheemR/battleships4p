extends Spatial

onready var carrier = $Carrier;
onready var battleship = $Battleship;
onready var submarine = $Submarine;
onready var destroyer = $Destroyer;
onready var cruiser = $Cruiser;

var current_ship = null;

func _ready():
	carrier.visible = false
	battleship.visible = false
	submarine.visible = false
	destroyer.visible = false
	cruiser.visible = false

func _on_WSHandler_start_placement(_ids):
	
	current_ship = carrier
	carrier.visible = true
	
	
func _input(event):
	if current_ship:
		if event.is_action_pressed("ui_up"):
			current_ship.translation.x += 1
		if event.is_action_pressed("ui_down"):
			current_ship.translation.x -= 1
		if event.is_action_pressed("ui_right"):
			current_ship.translation.z += 1
		if event.is_action_pressed("ui_left"):
			current_ship.translation.z -= 1
		if event.is_action_pressed("ui_select"):
			current_ship.rotation.y += PI/2
			current_ship.rotation.y = fmod(current_ship.rotation.y, 2 * PI)


		if event.is_action_pressed("ui_accept"):
			if current_ship == carrier:
				current_ship = battleship
			elif current_ship == battleship:
				current_ship = submarine
			elif current_ship == submarine:
				current_ship = destroyer
			elif current_ship == destroyer:
				current_ship = cruiser
			elif current_ship == cruiser:
				current_ship = null
				var data = generateShipData()
				sendShipData(data)

			if current_ship:
				current_ship.visible = true

func generateShipData():
	var data = {
		"carrierLocation": getShipCoord(carrier),
		"carrierDirection": getShipDirection(carrier),
		"battleshipLocation": getShipCoord(battleship),
		"battleshipDirection": getShipDirection(battleship),
		"submarineLocation": getShipCoord(submarine),
		"submarineDirection": getShipDirection(submarine),
		"destroyerLocation": getShipCoord(destroyer),
		"destroyerDirection": getShipDirection(destroyer),
		"cruiserLocation": getShipCoord(cruiser),
		"cruiserDirection": getShipDirection(cruiser),
	}

	return data

func getShipCoord(shipnode):
	return [shipnode.translation.x, shipnode.translation.z]

func getShipDirection(shipnode):
	var angle = shipnode.rotation.y
	if angle < 0.1:
		return "north"
	if angle < PI/2 + 0.1:
		return "west"
	if angle < PI + 0.1:
		return "south"
	if angle < 3 * PI / 2 + 0.1:
		return "east"

func sendShipData(data):
	$"/root/GameMain/WSHandler".send_msg("placements", data)