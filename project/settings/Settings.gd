extends Node

signal setting_changed

const IGNORE_SETTINGS_FILE = false
const SETTINGS_PATH = "user://settings.ini"

const SETTINGS_MENU = {
	"scene": preload("SettingsMenu.tscn"),
	"instance": null,
	"layer": 10
}

const REBINDABLE_ACTIONS = [
	#{ "action": "up", "name": "Move Up" },
	#{ "action": "down", "name": "Move Down" },
	#{ "action": "left", "name": "Move Left" },
	#{ "action": "right", "name": "Move Right" }
]

const ADJUSTABLE_VOLUMES = [
	{ "bus": "Master", "name": "Master" },
	{ "bus": "Music", "name": "Music" },
	{ "bus": "SFX", "name": "Sound Effects" }
]

const AUTO_SETTINGS = [
	{ "setting": "tilt_sensitivity", "feature": "mobile", "category": "Tilt Controls", "name": "Sensitivity", "type": "slider", "min": 10.0, "max": 110.0, "step": 1, "ticks": 6 },
	{ "setting": "tilt_dead_zone", "feature": "mobile", "category": "Tilt Controls", "name": "Dead Zone", "type": "slider", "min": 0.0, "max": 50.0, "step": 1, "ticks": 6 },
	{ "setting": "misc_vibration", "feature": "mobile", "category": "Misc", "name": "Vibrations", "type": "check" }
]

var tilt_sensitivity: float = 50.0
var tilt_dead_zone: float = 10.0
var misc_vibration: bool = true

func _ready():
	load_settings()
	for a in REBINDABLE_ACTIONS:
		a.default = InputMap.get_action_list(a.action)

func init_menu():
	SETTINGS_MENU.instance = SETTINGS_MENU.scene.instance()
	var layer = CanvasLayer.new()
	layer.layer = SETTINGS_MENU.layer
	layer.add_child(SETTINGS_MENU.instance)
	add_child(layer)

func show_menu():
	if SETTINGS_MENU.instance == null:
		init_menu()
	SETTINGS_MENU.instance.show_menu()

func change_setting(setting, new_value):
	if get(setting) != new_value:
		set(setting, new_value)
		emit_signal("setting_changed", setting, new_value)

func load_settings():
	var file = ConfigFile.new()
	var err = file.load(SETTINGS_PATH)
	if err != OK: return
	
	for sec in file.get_sections():
		if sec != "KEYBINDS" and sec != "VOLUME":
			for key in file.get_section_keys(sec):
				var prop_name = sec.to_lower() + "_" + key
				set(prop_name, file.get_value(sec, key))
	
	if file.has_section("KEYBINDS"):
		for i in REBINDABLE_ACTIONS:
			if file.has_section_key("KEYBINDS", i.action):
				var binds = file.get_value("KEYBINDS", i.action)
				var events = []
				for b in binds:
					var e = _dict_to_event(b)
					if e != null:
						events.append(e)
				if events.size() > 0:
					InputMap.action_erase_events(i.action)
					for e in events:
						InputMap.action_add_event(i.action, e)
						
	if file.has_section("VOLUME"):
		for i in ADJUSTABLE_VOLUMES:
			if file.has_section_key("VOLUME", i.bus):
				var vol = file.get_value("VOLUME", i.bus)
				AudioServer.set_bus_volume_db(AudioServer.get_bus_index(i.bus), vol)

func save_settings():
	var file = ConfigFile.new()
	
	for prop in get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE != 0:
			var i = prop.name.find("_")
			if i > 1:
				var sec = prop.name.substr(0, i).to_upper()
				var key = prop.name.substr(i + 1, prop.name.length() - i - 1)
				file.set_value(sec, key, get(prop.name))
			
	for i in REBINDABLE_ACTIONS:
		var list = InputMap.get_action_list(i.action)
		print(list)
		var binds = []
		for e in list:
			var d = _event_to_dict(e)
			if d != null:
				binds.append(d)
		print(binds)
		if binds.size() > 0:
			print("yay")
			file.set_value("KEYBINDS", i.action, binds)
			
	for i in ADJUSTABLE_VOLUMES:
		var vol = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(i.bus))
		file.set_value("VOLUME", i.bus, vol)
		
	file.save(SETTINGS_PATH)

func _event_to_dict(event):
	var dict = {}
	if event is InputEventKey:
		dict.type = "key"
		dict.key = event.scancode
	elif event is InputEventMouseButton:
		dict.type = "mouse"
		dict.button = event.button_index
	elif event is InputEventJoypadButton:
		dict.type = "joy"
		dict.button = event.button_index
	else:
		return null
	return dict
	
func _dict_to_event(dict):
	var event = null
	if dict.type == "key":
		event = InputEventKey.new()
		event.pressed = true
		event.scancode = dict.key
	elif dict.type == "mouse":
		event = InputEventMouseButton.new()
		event.pressed = true
		event.button_index = dict.button
	elif dict.type == "joy":
		event = InputEventJoypadButton.new()
		event.pressed = true
		event.button_index = dict.button
	else:
		return null
	return event
