extends HBoxContainer

signal value_changed

func init(setting):
	$Label.text = setting.name
	$HSlider.min_value = setting.min
	$HSlider.max_value = setting.max
	$HSlider.step = setting.step
	if "ticks" in setting:
		$HSlider.tick_count = setting.ticks

func update_value(val):
	$HSlider.value = val
	$Value.text = str(val)

func _on_HSlider_value_changed(value):
	$Value.text = str(value)
	emit_signal("value_changed", value)
