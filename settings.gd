@tool
extends VBoxContainer
class_name Settings


signal should_convert_image_to_pixel(image: Image)
signal should_convert_text_to_pixel(text: String)
signal should_renew_board(
	full_half_width: Board.FullHalfWidth,
	char_half_width: int,
	char_height: int,
	char_count: int,
)
signal should_save_image(path: String)
signal should_set_annotation(annotation: String)
signal should_set_board_background_color(background_color: Color)
signal should_set_board_block_size(block_size: int)


var backround_color := Color.OLD_LACE:
	set(value):
		backround_color = value
		window_default_setting.background_color = value
var block_size := 30:
	set(value):
		block_size = value
		window_default_setting.block_size = value
var code := ""


var _full_half_width := Board.FullHalfWidth.HALF:
	set(value):
		if _full_half_width == value:
			return
		_full_half_width = value
		option_button_full_half_width.selected = 0 if value == Board.FullHalfWidth.HALF else 1
		renew_board()
var _char_half_width = 8:
	set(value):
		if _char_half_width == value:
			return
		_char_half_width = value
		spin_box_char_half_width.value = value
		renew_board()
var _char_height = 16:
	set(value):
		if _char_height == value:
			return
		_char_height = value
		spin_box_char_height.value = value
		renew_board()
var _char_count = 1:
	set(value):
		if _char_count == value:
			return
		_char_count = value
		spin_box_char_count.value = value
		renew_board()
var _project_name := "":
	set(value):
		_project_name = value
		if not is_node_ready():
			await ready
		label_project_name.text = "目前專案: " + value
		button_save_image.text = "生成圖片檔(" + value + ".png)"


@onready var window_create_project: WindowCreateProject = %WindowCreateProject
@onready var window_default_setting: WindowDefaultSetting = %WindowDefaultSetting
@onready var v_box_container_project: VBoxContainer = %VBoxContainerProject
@onready var label_project_name: Label = %LabelProjectName
@onready var option_button_full_half_width: OptionButton = %OptionButtonFullHalfWidth
@onready var spin_box_char_half_width: SpinBox = %SpinBoxCharHalfWidth
@onready var spin_box_char_height: SpinBox = %SpinBoxCharHeight
@onready var spin_box_char_count: SpinBox = %SpinBoxCharCount
@onready var line_edit_text_to_pixel: LineEdit = %LineEditTextToPixel
@onready var button_text_to_pixel: Button = %ButtonTextToPixel
@onready var file_dialog_txt_file_to_pixel: FileDialog = %FileDialogTxtFileToPixel
@onready var file_dialog_img_file_to_pixel: FileDialog = %FileDialogImgFileToPixel
@onready var line_edit_annotation: LineEdit = %LineEditAnnotation
@onready var window_preview_code: WindowPreviewCode = %WindowPreviewCode
@onready var button_save_image: Button = %ButtonSaveImage


func _ready() -> void:
	window_default_setting.color_picker_button.color_changed.connect(func(color: Color):
		should_set_board_background_color.emit(color)
	)
	window_default_setting.spin_box_block_size.value_changed.connect(func(value: int):
		should_set_board_block_size.emit(value)
	)


func renew_board() -> void:
	should_renew_board.emit(_full_half_width, _char_half_width, _char_height, _char_count)


func _on_button_create_project_pressed() -> void:
	window_create_project.visible = true


func _on_window_create_project_should_create_project(
	full_half_width: Board.FullHalfWidth,
	char_half_width: int,
	char_height: int,
	char_count: int,
	project_name: String
) -> void:
	v_box_container_project.visible = true
	_full_half_width = full_half_width
	_char_half_width = char_half_width
	_char_height = char_height
	_char_count = char_count
	_project_name = project_name
	renew_board()

func _on_button_default_setting_pressed() -> void:
	window_default_setting.visible = true


func _on_option_button_full_half_width_item_selected(index: int) -> void:
	_full_half_width = Board.FullHalfWidth.FULL if index == 1 else Board.FullHalfWidth.HALF


func _on_spin_box_char_half_width_value_changed(value: float) -> void:
	_char_half_width = value


func _on_spin_box_char_height_value_changed(value: float) -> void:
	_char_height = value


func _on_spin_box_char_count_value_changed(value: float) -> void:
	_char_count = value


func _on_button_text_to_pixel_pressed() -> void:
	var text := line_edit_text_to_pixel.text
	_char_count = text.length()
	_char_half_width = 8
	_char_height = 16
	line_edit_annotation.text_changed.emit(",".join(text.split("")))
	should_convert_text_to_pixel.emit(text)


func _on_check_box_native_dialog_toggled(toggled_on: bool) -> void:
	file_dialog_img_file_to_pixel.use_native_dialog = toggled_on
	file_dialog_txt_file_to_pixel.use_native_dialog = toggled_on


func _on_button_txt_file_to_pixel_pressed() -> void:
	file_dialog_txt_file_to_pixel.visible = true


func _on_file_dialog_txt_file_to_pixel_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file != null:
		var text := file.get_as_text(true).replace("\n", "")
		line_edit_text_to_pixel.text = text
		file.close()
		line_edit_text_to_pixel.text_changed.emit(text)
		button_text_to_pixel.pressed.emit()


func _on_button_img_file_to_pixel_pressed() -> void:
	file_dialog_img_file_to_pixel.visible = true


func _on_file_dialog_img_file_to_pixel_file_selected(path: String) -> void:
	var image := Image.load_from_file(path)
	should_convert_image_to_pixel.emit(image)


func _on_line_edit_annotation_text_changed(new_text: String) -> void:
	if line_edit_annotation.text != new_text:
		line_edit_annotation.text = new_text
	should_set_annotation.emit(new_text)


func _on_button_preview_code_pressed() -> void:
	window_preview_code.code = code
	window_preview_code.project_name = _project_name
	window_preview_code.visible = true


func _on_button_save_image_pressed() -> void:
	should_save_image.emit(_project_name + ".png")
