@tool
extends Control


@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var option_button_full_half: OptionButton = %OptionButtonFullHalf
@onready var line_edit_text_to_pixel: LineEdit = %LineEditTextToPixel
@onready var line_edit_image_to_pixel: LineEdit = %LineEditImageToPixel
@onready var line_edit_annotation: LineEdit = %LineEditAnnotation
@onready var line_edit_annotation_2: LineEdit = %LineEditAnnotation2
@onready var line_edit_save: LineEdit = %LineEditSave
@onready var board: Container = %Board
@onready var sub_viewport: SubViewport = %SubViewport
@onready var label_text: Label = %LabelText


func _on_v_box_container_resized() -> void:
	if not is_node_ready():
		await ready
	if not Engine.is_editor_hint():
		get_tree().get_root().get_window().size = v_box_container.size


func _on_button_add_pressed() -> void:
	board.add(
		"half" if option_button_full_half.selected == 0 else
		"full"
	)


func _on_button_delete_pressed() -> void:
	board.delete()


func _on_spin_box_block_size_value_changed(value: float) -> void:
	board.block_size = value


func _on_button_text_to_pixel_pressed() -> void:
	label_text.text = line_edit_text_to_pixel.text
	label_text.position.x = 0
	for item in board.h_box_container.get_children():
		sub_viewport.size.x = board.full_width_size.x
		if item.find_child("%d %d" % [0, board.half_width_size.x], true, false) == null:
			sub_viewport.size.x = board.half_width_size.x
		await RenderingServer.frame_post_draw
		var image := sub_viewport.get_texture().get_image()
		for y in range(board.half_width_size.y):
			for x in range(sub_viewport.size.x):
				var _texture_button = item.find_child("%d %d" % [y, x], true, false) as TextureButton
				_texture_button.texture_normal = (
					board._image_texture_black if image.get_pixel(x, y) == Color.BLACK else
					board._image_texture_background
				)
		label_text.position.x -= sub_viewport.size.x


func _on_button_image_to_pixel_pressed() -> void:
	var image := Image.load_from_file(line_edit_image_to_pixel.text)
	if image != null:
		image.resize(
			image.get_size().x * board.half_width_size.y / image.get_size().y,
			board.half_width_size.y,
		)

		var width_count := 0
		for item in board.h_box_container.get_children():
			var width := board.full_width_size.x as int
			if item.find_child("%d %d" % [0, board.half_width_size.x], true, false) == null:
				width = board.half_width_size.x
			for y in range(board.half_width_size.y):
				for x in range(width):
					if x + width_count >= image.get_size().x or y >= image.get_size().y:
						continue
					var _texture_button = item.find_child("%d %d" % [y, x], true, false) as TextureButton
					_texture_button.texture_normal = (
						board._image_texture_black if image.get_pixel(width_count + x, y).get_luminance() < 0.5 else
						board._image_texture_background
					)
			width_count += width


func _on_button_save_pressed() -> void:
	var file := FileAccess.open(line_edit_save.text, FileAccess.WRITE)
	if FileAccess.get_open_error() == OK:
		var half_indexes := []
		var full_indexes := []
		var count := 0
		for item in board.h_box_container.get_children():
			if item.find_child("%d %d" % [0, board.half_width_size.x], true, false) == null:
				half_indexes.append(count)
			else:
				full_indexes.append(count)
			count += 1

		if count == 0:
			return

		var image := Image.new()
		image.set_data(
			1,
			1,
			false,
			Image.FORMAT_RGB8,
			[0, 0, 0],
		)
		image.resize(
			half_indexes.size() * board.half_width_size.x + full_indexes.size() * board.full_width_size.x,
			board.half_width_size.y,
		)

		file.store_string("const BYTE half[%d][%d][%d] = {\n" % [half_indexes.size(), 2, board.half_width_size.x])

		count = 0
		var half_annotations := line_edit_annotation.text.split(",")
		var width_count = 0
		for index in half_indexes:
			file.store_string("\t{ // %d: %s\n" % [count, half_annotations[count] if count < half_annotations.size() else ""])
			var item := board.h_box_container.get_child(index) as Node
			file.store_string("\t\t{")
			for x in range(board.half_width_size.x):
				var n := 0
				for y in range(7, -1, -1):
					var _texture_button := item.find_child("%d %d" % [y, x], true, false) as TextureButton
					image.set_pixel(
						x + width_count,
						y,
						Color.BLACK if _texture_button.texture_normal.get_image().get_pixel(0, 0) == Color.BLACK else
						Color.WHITE,
					)

					n <<= 1
					if _texture_button.texture_normal.get_image().get_pixel(0, 0) == Color.BLACK:
						n += 1
				file.store_string("0x%02x, " % [n])
			file.store_string("},\n")
			file.store_string("\t\t{")
			for x in range(board.half_width_size.x):
				var n := 0
				for y in range(15, 7, -1):
					var _texture_button := item.find_child("%d %d" % [y, x], true, false) as TextureButton
					image.set_pixel(
						x + width_count,
						y,
						Color.BLACK if _texture_button.texture_normal.get_image().get_pixel(0, 0) == Color.BLACK else
						Color.WHITE,
					)

					n <<= 1
					if _texture_button.texture_normal.get_image().get_pixel(0, 0) == Color.BLACK:
						n += 1
				file.store_string("0x%02x, " % [n])
			file.store_string("},\n")
			file.store_string("\t},\n")

			width_count += board.half_width_size.x
			count += 1
		file.store_string("};\n")
		file.store_string("const BYTE full[%d][%d][%d] = {\n" % [full_indexes.size(), 2, board.full_width_size.x])

		count = 0
		var full_annotations := line_edit_annotation_2.text.split(",")
		for index in full_indexes:
			file.store_string("\t{ // %d: %s\n" % [count, full_annotations[count] if count < full_annotations.size() else ""])
			var item := board.h_box_container.get_child(index) as Node
			file.store_string("\t\t{")
			for x in range(board.full_width_size.x):
				var n := 0
				for y in range(7, -1, -1):
					var _texture_button := item.find_child("%d %d" % [y, x], true, false) as TextureButton
					image.set_pixel(
						x + width_count,
						y,
						Color.BLACK if _texture_button.texture_normal.get_image().get_pixel(0, 0) == Color.BLACK else
						Color.WHITE,
					)

					n <<= 1
					if _texture_button.texture_normal.get_image().get_pixel(0, 0) == Color.BLACK:
						n += 1
				file.store_string("0x%02x, " % [n])
			file.store_string("},\n")
			file.store_string("\t\t{")
			for x in range(board.full_width_size.x):
				var n := 0
				for y in range(15, 7, -1):
					var _texture_button := item.find_child("%d %d" % [y, x], true, false) as TextureButton
					image.set_pixel(
						x + width_count,
						y,
						Color.BLACK if _texture_button.texture_normal.get_image().get_pixel(0, 0) == Color.BLACK else
						Color.WHITE,
					)

					n <<= 1
					if _texture_button.texture_normal.get_image().get_pixel(0, 0) == Color.BLACK:
						n += 1
				file.store_string("0x%02x, " % [n])
			file.store_string("},\n")
			file.store_string("\t},\n")

			width_count += board.full_width_size.x
			count += 1
		file.store_string("};\n")
		file.close()

		image.save_png(line_edit_save.text + ".png")
