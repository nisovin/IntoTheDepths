extends Control

onready var menu = $CenterContainer/Menu

var play_sample_sound_in = -1

func _ready():
	Game.play_music()
	Game.skip = 0
	for u in Game.upgrades:
		var b = menu.get_node(u + "/Button")
		b.connect("pressed", self, "_on_buy_pressed", [u])
		b.connect("mouse_entered", self, "_on_mouseover")
	for s in Game.skips:
		var b = menu.get_node("skip_" + str(s.to) + "/Button")
		b.connect("pressed", self, "_on_skip_pressed", [s])
		b.connect("mouse_entered", self, "_on_mouseover")
	update_labels()
	menu.get_node("Last").text = "Last: " + str(Game.last_depth)
	menu.get_node("Best").text = "Best: " + str(Game.max_depth)
	if Game.last_texture != null:
		$TextureRect.texture = Game.last_texture
	menu.find_node("MainVolume").value = db2linear(AudioServer.get_bus_volume_db(0))
	menu.find_node("EffectsVolume").value = db2linear(AudioServer.get_bus_volume_db(1))
	menu.find_node("MusicVolume").value = db2linear(AudioServer.get_bus_volume_db(2))
	play_sample_sound_in = -1

func update_labels():
	menu.get_node("Gold").text = "Gold: " + str(floor(Game.gold))
	for u in Game.upgrades:
		var level = Game.get(u)
		var cost = Game.upgrades[u].execute([level])
		var cost_str = str(cost)
		if cost > 10000:
			cost_str = str(ceil(cost / 1000.0)) + "K"
		menu.get_node(u + "/Value").text = str(level)
		menu.get_node(u + "/Cost").text = "$" + cost_str
		menu.get_node(u + "/Button").disabled = Game.gold < cost
	for s in Game.skips:
		menu.get_node("skip_" + str(s.to)).visible = Game.max_depth >= s.requires
		menu.get_node("skip_" + str(s.to) + "/Cost").text = "$" + str(s.cost)
		menu.get_node("skip_" + str(s.to) + "/Button").disabled = Game.gold < s.cost or Game.skip > 0

func _on_buy_pressed(up):
	var level = Game.get(up)
	var cost = Game.upgrades[up].execute([level])
	if Game.gold >= cost:
		Game.gold -= cost
		Game.set(up, level + 1)
		update_labels()
		Game.play_audio("click")

func _on_skip_pressed(s):
	if Game.gold >= s.cost:
		Game.gold -= s.cost
		Game.skip = s.to
		update_labels()
		Game.play_audio("click")

func _on_Done_pressed():
	Game.save_game()
	Game.play_audio("click")
	get_tree().change_scene("res://level/Level.tscn")

func _unhandled_key_input(event):
	if event.scancode == KEY_F5 and event.pressed and Input.is_key_pressed(KEY_SHIFT):
		Game.gold += 5000
		update_labels()

func _on_MainVolume_value_changed(value):
	AudioServer.set_bus_volume_db(0, linear2db(value))

func _on_EffectsVolume_value_changed(value):
	AudioServer.set_bus_volume_db(1, linear2db(value))
	play_sample_sound_in = 0.25

func _on_MusicVolume_value_changed(value):
	AudioServer.set_bus_volume_db(2, linear2db(value))

func _process(delta):
	if play_sample_sound_in > 0:
		play_sample_sound_in -= delta
		if play_sample_sound_in <= 0:
			Game.play_audio("explode")


func _on_mouseover():
	Game.play_audio("rollover")
