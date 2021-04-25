extends Control

func _on_Play_pressed():
	Game.play_audio("click")
	get_tree().change_scene("res://level/Level.tscn")

func _on_Quit_pressed():
	get_tree().quit()


func _on_mouse_entered():
	Game.play_audio("rollover")
