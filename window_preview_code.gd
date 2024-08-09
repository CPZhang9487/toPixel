@tool
extends Window
class_name WindowPreviewCode


var code = "":
	set(value):
		code = value
		code_edit.text = code
var project_name = "":
	set(value):
		project_name = value
		button_save.text = "存檔(%s.c)" % [value]


@onready var button_save: Button = %ButtonSave
@onready var code_edit: CodeEdit = %CodeEdit


func _on_close_requested() -> void:
	visible = false


func _on_button_save_pressed() -> void:
	var file := FileAccess.open(project_name + ".c", FileAccess.WRITE)
	if file != null:
		file.store_string(code)
		file.close()
	visible = false
