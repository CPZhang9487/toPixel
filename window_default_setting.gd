@tool
extends Window
class_name WindowDefaultSetting


var background_color := Color.OLD_LACE:
	set(value):
		background_color = value
		color_picker_button.color = value
var block_size := 30:
	set(value):
		block_size = value
		spin_box_block_size.value = value


@onready var color_picker_button: ColorPickerButton = %ColorPickerButton
@onready var spin_box_block_size: SpinBox = %SpinBoxBlockSize


func _on_close_requested() -> void:
	visible = false
