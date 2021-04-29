extends HBoxContainer

signal value_changed

func init(setting):
	$Label.text = setting.name
	$SpinBox.min_value = setting.min
	$SpinBox.max_value = setting.max
	$SpinBox.step = setting.step
	if "greater" in setting:
		$SpinBox.allow_greater = setting.greater
	if "lesser" in setting:
		$SpinBox.allow_lesser = setting.lesser

func update_value(val):
	$SpinBox.value = val
	$Value.text = str(val)

func _on_SpinBox_value_changed(value):
	$Value.text = str(value)
	emit_signal("value_changed", value)
