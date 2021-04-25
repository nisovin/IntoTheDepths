extends CanvasLayer

onready var slow_time_progress = $SlowTime
onready var slow_time_label = $SlowTime/Label
onready var slow_time_tween = $SlowTimeTween
onready var missiles_label = $Missiles
onready var shields_label = $Shields
onready var depth_label = $Depth
onready var multiplier_label = $Multiplier

func _ready():
	slow_time_progress.max_value = Game.slow_time + 1
	update_slow_time(Game.slow_time, false)
	update_missiles(Game.missiles)
	update_shields(Game.shields)
	update_multiplier(Game.gold_multiplier + 1)
	if Game.first_run:
		slow_time_progress.hide()
		missiles_label.hide()
		shields_label.hide()
		multiplier_label.hide()

func update_slow_time(value, tween):
	if tween:
		slow_time_tween.remove_all()
		slow_time_tween.interpolate_property(slow_time_progress, "value", slow_time_progress.value, value, 0.5, Tween.TRANS_EXPO, Tween.EASE_OUT)
		slow_time_tween.start()
	else:
		slow_time_tween.remove_all()
		slow_time_progress.value = value
	slow_time_label.text = str(stepify(value, 0.1)) + " s"
	if not slow_time_progress.visible:
		slow_time_progress.show()
		# TODO: show hint
	
func update_missiles(value):
	missiles_label.text = str(value)
	missiles_label.set("custom_colors/font_color", Color.red if value > 0 else Color.black)
	if not missiles_label.visible:
		missiles_label.show()
		# TODO: show hint

func update_shields(value):
	shields_label.text = str(value)
	shields_label.set("custom_colors/font_color", Color.cyan if value > 0 else Color.black)

func update_depth(value):
	depth_label.text = str(floor(value))

func update_multiplier(value):
	multiplier_label.text = "x" + str(floor(value))
