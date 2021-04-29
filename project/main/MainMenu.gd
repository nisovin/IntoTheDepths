extends Control

func _ready():
	if OS.has_feature("mobile"):
		$CenterContainer/VBoxContainer/FullScreen.hide()
	if OS.has_feature("web"):
		$CenterContainer/VBoxContainer/Quit.hide()

func _on_Play_pressed():
	Game.play_audio("click")
	if Game.first_run:
		get_tree().change_scene("res://level/Level.tscn")
	else:
		get_tree().change_scene("res://main/Shop.tscn")

func _on_Reset_pressed():
	Game.reset_save()

func _on_FullScreen_pressed():
	OS.window_fullscreen = not OS.window_fullscreen

func _on_Quit_pressed():
	get_tree().quit()

func _on_mouse_entered():
	Game.play_audio("rollover")

