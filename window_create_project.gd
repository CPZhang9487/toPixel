@tool
extends Window
class_name WindowCreateProject


signal should_create_project(
	full_half_width: Board.FullHalfWidth,
	char_half_width: int,
	char_height: int,
	char_count: int,
	project_name: String,
)


@onready var option_button_full_half_width: OptionButton = %OptionButtonFullHalfWidth
@onready var spin_box_char_half_width: SpinBox = %SpinBoxCharHalfWidth
@onready var spin_box_char_height: SpinBox = %SpinBoxCharHeight
@onready var spin_box_char_count: SpinBox = %SpinBoxCharCount
@onready var line_edit_project_name: LineEdit = %LineEditProjectName
@onready var label_error: Label = %LabelError


func _on_close_requested() -> void:
	visible = false


func _on_button_create_pressed() -> void:
	label_error.visible = false
	var project_name := line_edit_project_name.text
	for _char in "\\/:*?\"<>|":
		if _char in project_name:
			label_error.text = "專案名稱不能包含 \\/:*?\"<>|"
			label_error.visible = true
			return

	var file := FileAccess.open(project_name, FileAccess.WRITE)
	if file == null:
		label_error.text = "建立專案失敗，檢查專案名稱是否正確。"
		label_error.visible = true
		return
	file.close()
	DirAccess.remove_absolute(project_name)

	visible = false

	should_create_project.emit(
		Board.FullHalfWidth.FULL if option_button_full_half_width.selected == 1 else Board.FullHalfWidth.HALF,
		spin_box_char_half_width.value,
		spin_box_char_height.value,
		spin_box_char_count.value,
		project_name,
	)
