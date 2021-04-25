extends Control

onready var menu = $CenterContainer/Menu

func _ready():
	for u in Game.upgrades:
		menu.get_node(u + "/Button").connect("pressed", self, "_on_buy_pressed", [u])
	update_labels()
	menu.get_node("Last").text = "Last: " + str(Game.last_depth)
	menu.get_node("Best").text = "Best: " + str(Game.max_depth)

func update_labels():
	menu.get_node("Gold").text = "Gold: " + str(floor(Game.gold))
	for u in Game.upgrades:
		var level = Game.get(u)
		var cost = Game.upgrades[u].execute([level])
		var cost_str = str(cost)
		if cost > 10000:
			cost_str = str(ceil(cost / 1000.0)) + "K"
		menu.get_node(u + "/Value").text = str(level)
		menu.get_node(u + "/Cost").text = cost_str
		menu.get_node(u + "/Button").disabled = Game.gold < cost

func _on_buy_pressed(up):
	var level = Game.get(up)
	var cost = Game.upgrades[up].execute([level])
	if Game.gold >= cost:
		Game.gold -= cost
		Game.set(up, level + 1)
		update_labels()


func _on_Done_pressed():
	Game.save_game()
	get_tree().change_scene("res://level/Level.tscn")
