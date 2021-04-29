extends PopupPanel

const BindingEntry = preload("BindingEntry.tscn")
const SliderEntry = preload("SliderEntry.tscn")
const SpinnerEntry = preload("SpinnerEntry.tscn")
const CheckboxEntry = preload("CheckboxEntry.tscn")

onready var settings_container = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Settings
onready var bindings_container = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Bindings
onready var volumes_container = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/Volumes
onready var subtitle_example = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/LabelVolume
onready var label_bindings = $MarginContainer/VBoxContainer/ScrollContainer/VBoxContainer/LabelBindings

var current_settings = {}
var current_bindings = {}
var current_volumes = {}

var setting_nodes = {}
var changing_binding = false
var changing_binding_action = ""
var changing_binding_index = 0

func _ready():
	var last_category = ""
	for s in Settings.AUTO_SETTINGS:
		if "feature" in s and not OS.has_feature(s.feature):
			continue
		if last_category != s.category:
			last_category = s.category
			var label = Label.new()
			label.set("custom_fonts/font", subtitle_example.get("custom_fonts/font"))
			label.text = s.category
			label.align = Label.ALIGN_CENTER
			settings_container.add_child(label)
		var ctrl = null
		if s.type == "slider":
			ctrl = SliderEntry.instance()
		elif s.type == "spinner":
			ctrl = SpinnerEntry.instance()
		elif s.type == "check":
			ctrl = CheckboxEntry.instance()
		else:
			assert(false)
		ctrl.init(s)
		ctrl.connect("value_changed", self, "_on_setting_changed", [s.setting])
		settings_container.add_child(ctrl)
		setting_nodes[s.setting] = ctrl
		
	for v in Settings.ADJUSTABLE_VOLUMES:
		var entry = SliderEntry.instance()
		entry.init({"name": v.name, "min": 0, "max": 100, "step": 1})
		entry.connect("value_changed", self, "_on_volume_changed", [v.bus])
		volumes_container.add_child(entry)
		
	if OS.has_feature("mobile"):
		label_bindings.hide()
		bindings_container.hide()
	else:
		for a in Settings.REBINDABLE_ACTIONS:
			var entry = BindingEntry.instance()
			entry.init(a.action, a.name)
			entry.connect("binding_clicked", self, "_on_binding_clicked")
			bindings_container.add_child(entry)
		
	#show_menu()
	
func _dict_val(dict, key, default):
	if key in dict:
		return dict[key]
	else:
		return default
	
func _input(event):
	if changing_binding:
		if event.is_action_pressed("ui_cancel"):
			changing_binding = false
			get_tree().set_input_as_handled()
		elif event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton):
			var s = event_string(event)
			if s != "":
				event = clean_event(event)
				if event:
					var bindings = current_bindings[changing_binding_action]
					if changing_binding_index >= bindings.size():
						bindings.resize(changing_binding_index + 1)
					bindings[changing_binding_index] = event
					changing_binding = false
					update_binding_strings()
					

func show_menu():
	current_settings = {}
	for s in Settings.AUTO_SETTINGS:
		current_settings[s.setting] = Settings.get(s.setting)
	current_bindings = {}
	for a in Settings.REBINDABLE_ACTIONS:
		 current_bindings[a.action] = InputMap.get_action_list(a.action)
	current_volumes = {}
	for b in Settings.ADJUSTABLE_VOLUMES:
		current_volumes[b.bus] = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(b.bus))
	update_binding_strings()
	update_volume_bars()
	update_setting_controls()
	popup_centered()
	
func _on_volume_changed(value, bus):
	current_volumes[bus] = linear2db(value / 100.0)
	
func _on_binding_clicked(action, index):
	changing_binding = true
	changing_binding_action = action
	changing_binding_index = index

func _on_setting_changed(value, setting):
	current_settings[setting] = value
	print(setting, " ", value)

func _on_apply():
	commit()

func _on_save():
	commit()
	hide()
	
func _on_cancel():
	hide()

func commit():
	for setting in current_settings:
		Settings.change_setting(setting, current_settings[setting])
	for bus in current_volumes:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), current_volumes[bus])
	for action in current_bindings:
		InputMap.action_erase_events(action)
		for e in current_bindings[action]:
			InputMap.action_add_event(action, e)
	Settings.save_settings()

func update_binding_strings():
	for i in Settings.REBINDABLE_ACTIONS.size():
		var action = Settings.REBINDABLE_ACTIONS[i].action
		var bindings = []
		for e in current_bindings[action]:
			bindings.append(event_string(e))
		bindings_container.get_child(i).update_bindings(bindings)

func update_volume_bars():
	for i in Settings.ADJUSTABLE_VOLUMES.size():
		var v = Settings.ADJUSTABLE_VOLUMES[i]
		volumes_container.get_child(i).update_value(clamp(round(db2linear(current_volumes[v.bus]) * 100), 0, 100))

func update_setting_controls():
	for s in Settings.AUTO_SETTINGS:
		if s.setting in setting_nodes:
			setting_nodes[s.setting].update_value(Settings.get(s.setting))

func clean_event(event):
	if event is InputEventKey:
		var e = InputEventKey.new()
		e.scancode = event.scancode
		e.pressed = true
		return e
	elif event is InputEventMouseButton:
		var e = InputEventMouseButton.new()
		e.button_index = event.button_index
		e.pressed = true
		return e
	elif event is InputEventJoypadButton:
		var e = InputEventJoypadButton.new()
		e.button_index = event.button_index
		e.pressed = true
		return e

func event_string(event):
	if event is InputEventKey:
		return OS.get_scancode_string(event.scancode)
	elif event is InputEventMouseButton:
		var s = "Mouse Button"
		match event.button_index:
			BUTTON_LEFT:
				s = "Left Click"
			BUTTON_RIGHT:
				s = "Right Click"
			BUTTON_MIDDLE:
				s = "Middle Click"
			BUTTON_WHEEL_DOWN:
				s = "Scroll Down"
			BUTTON_WHEEL_UP:
				s = "Scroll Up"
			BUTTON_WHEEL_LEFT:
				s = "Scroll Left"
			BUTTON_WHEEL_RIGHT:
				s = "Scroll Right"
			BUTTON_XBUTTON1:
				s = "Mouse 4"
			BUTTON_XBUTTON2:
				s = "Mouse 5"
		return s
	elif event is InputEventJoypadButton:
		return Input.get_joy_button_string(event.button_index)
	else:
		return ""
		
