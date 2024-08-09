@tool
extends Control


@onready var settings: Settings = $VBoxContainer/Settings
@onready var board: Board = %Board


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("add_block_size"):
		board.block_size += 1
	elif Input.is_action_just_pressed("sub_block_size"):
		board.block_size -= 1


func _on_settings_should_convert_image_to_pixel(image: Image) -> void:
	board.convert_image_to_pixel(image)


func _on_settings_should_convert_text_to_pixel(text: String) -> void:
	board.convert_text_to_pixel(text)


func _on_settings_should_renew_board(
	full_half_width: Board.FullHalfWidth,
	char_half_width: int,
	char_height: int,
	char_count: int,
) -> void:
	board.renew(full_half_width, char_half_width, char_height, char_count)


func _on_settings_should_save_image(path: String) -> void:
	board.save_image(path)


func _on_settings_should_set_annotation(annotation: String) -> void:
	board.annotation = annotation


func _on_settings_should_set_board_background_color(background_color: Color) -> void:
	board.background_color = background_color


func _on_settings_should_set_board_block_size(block_size: int) -> void:
	board.block_size = block_size


func _on_board_background_color_changed(value: Color) -> void:
	settings.backround_color = value


func _on_board_block_size_changed(value: int) -> void:
	settings.block_size = value


func _on_board_generated_code(code: String) -> void:
	settings.code = code


func _on_board_renewed(full_half_width: Board.FullHalfWidth, char_half_width: int, char_height: int, char_count: int) -> void:
	settings._full_half_width = full_half_width
	settings._char_half_width = char_half_width
	settings._char_height = char_height
	settings._char_count = char_count
