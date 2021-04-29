extends HBoxContainer

signal value_changed

func init(setting):
	$CheckBox.text = setting.name

func update_value(val):
	$CheckBox.pressed = val

func _on_CheckBox_toggled(button_pressed):
	emit_signal("value_changed", button_pressed)
