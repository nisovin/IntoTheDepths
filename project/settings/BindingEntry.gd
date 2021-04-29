extends Control

signal binding_clicked

var action

func _ready():
	var i = 0
	for child in $Buttons.get_children():
		child.connect("pressed", self, "_on_button_pressed", [i])
		i += 1

func init(action, action_name):
	self.action = action
	$Label.text = action_name

func update_bindings(bindings):
	for i in $Buttons.get_children().size():
		if bindings.size() > i:
			$Buttons.get_child(i).text = bindings[i]

func _on_button_pressed(index):
	emit_signal("binding_clicked", action, index)
