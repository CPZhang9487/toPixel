@tool
extends Control
class_name Board


signal background_color_changed(value: Color)
signal block_size_changed(value: int)
signal generated_code(code: String)
signal renewed(full_half_width: FullHalfWidth, char_half_width: int, char_height: int, char_count: int)


enum FullHalfWidth {
	FULL,
	HALF,
}


var annotation := ""
var background_color := Color.OLD_LACE:
	set(value):
		background_color = value
		background_color_changed.emit(value)
		queue_redraw()
var block_size := 30:
	set(value):
		if value < 1:
			value = 1
		block_size = value
		block_size_changed.emit(value)
		_resize()


var _char_half_width := 8
var _char_height := 16
var _mouse_left_pressed := false
var _mouse_right_pressed := false
var _full_half_width := FullHalfWidth.HALF
var _is_filled_arr := [[]]


@onready var sub_viewport: SubViewport = %SubViewport
@onready var label: Label = %Label
@onready var texture_rect: TextureRect = %TextureRect


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_mouse_left_pressed = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
		_mouse_right_pressed = event.button_index == MOUSE_BUTTON_RIGHT and event.pressed
		_set_pixel()
	elif event is InputEventMouseMotion:
		_set_pixel()


func _draw() -> void:
	draw_rect(
		Rect2(Vector2.ZERO, size),
		background_color,
	)
	for y in range(_char_height):
		for x in range(get_width()):
			draw_rect(
				Rect2(
					block_size * (x + 0.5),
					block_size * (y + 0.5),
					block_size,
					block_size,
				),
				Color.BLACK if _is_filled_arr[y][x] else background_color,
			)
	for y in range(_char_height + 1):
		draw_line(
			Vector2(block_size * 0.5, block_size * (y + 0.5)),
			Vector2(size.x - block_size * 0.5, block_size * (y + 0.5)),
			Color.BLACK,
			-1 if y % (_char_height / 2) != 0 and y != _char_height else 2,
		)
	for x in range(get_width() + 1):
		draw_line(
			Vector2(block_size * (x + 0.5), block_size * 0.5),
			Vector2(block_size * (x + 0.5), size.y - block_size * 0.5),
			Color.BLACK,
			-1 if x % (get_char_width()) != 0 else 2,
		)
	generated_code.emit(get_code())


func _ready() -> void:
	_resize()


func convert_image_to_pixel(image: Image):
	if image == null:
		return
	if get_width() == 0:
		return
	label.visible = false
	texture_rect.size.y = _char_height
	texture_rect.texture = ImageTexture.create_from_image(image)
	texture_rect.visible = true
	await RenderingServer.frame_post_draw
	renew(FullHalfWidth.HALF, _char_half_width, _char_height, ceil(texture_rect.size.x / get_char_width()))
	sub_viewport.size = Vector2(get_width(), _char_height)
	await RenderingServer.frame_post_draw
	var _image := sub_viewport.get_texture().get_image()
	for y in range(sub_viewport.size.y):
		for x in range(sub_viewport.size.x):
			_is_filled_arr[y][x] = _image.get_pixel(x, y).get_luminance() < 0.5
	queue_redraw()


func convert_text_to_pixel(text: String) -> void:
	if get_width() == 0:
		return
	sub_viewport.size = Vector2(get_width(), _char_height)
	label.text = text
	label.visible = true
	texture_rect.visible = false
	await RenderingServer.frame_post_draw
	var image := sub_viewport.get_texture().get_image()
	for y in range(sub_viewport.size.y):
		for x in range(sub_viewport.size.x):
			_is_filled_arr[y][x] = image.get_pixel(x, y) == Color.BLACK
	queue_redraw()


func get_char_count() -> int:
	if _is_filled_arr.size() == 0:
		return 0
	return get_width() / get_char_width()


func get_char_width() -> int:
	return _char_half_width * (2 if _full_half_width == FullHalfWidth.FULL else 1)


func get_code() -> String:
	var result := "const BYTE arr[%d][%d][%d] = { // %s\n" % [get_char_count(), 2, get_char_width(), annotation]
	var annotations := annotation.split(",")
	for i in range(get_char_count()):
		result += "\t{ // %d == %s\n" % [i, "" if annotations.size() <= i else annotations[i]]
		for j in range(2):
			result += "\t\t{"
			for x in range(get_char_width()):
				var n := 0
				for y in range(_char_height / 2 * (j + 1) - 1, _char_height / 2 * j -1, -1):
					n <<= 1
					if _is_filled_arr[y][x + i * get_char_width()]:
						n += 1
				result += "0x%02x, " % [n]
			result += "},\n"
		result += "\t}, // %d == %s\n" % [i, "" if annotations.size() <= i else annotations[i]]
	result += "};\n\n"
	return result


func get_width() -> int:
	return _is_filled_arr[0].size()


func renew(full_half_width: FullHalfWidth, char_half_width: int, char_height: int, char_count: int) -> void:
	_full_half_width = full_half_width
	_char_half_width = char_half_width
	_char_height = char_height

	_is_filled_arr.clear()
	for y in range(_char_height):
		var _arr := []
		_arr.resize(get_char_width() * char_count)
		_arr.fill(false)
		_is_filled_arr.append(_arr)

	_resize()

	renewed.emit(full_half_width, char_half_width, char_height, char_count)


func save_image(path: String) -> void:
	var image := Image.new()
	image.set_data(1, 1, false, Image.FORMAT_RGB8, [0, 0, 0])
	image.resize(get_width(), _char_height)
	for y in _char_height:
		for x in get_width():
			image.set_pixel(x, y, Color.BLACK if _is_filled_arr[y][x] else Color.WHITE)
	image.save_png(path)


func _resize() -> void:
	custom_minimum_size = Vector2.ZERO
	size = Vector2(
		block_size * (get_width() + 1),
		block_size * (_char_height + 1),
	)
	custom_minimum_size = size

	queue_redraw()


func _set_pixel() -> void:
	var coord := get_local_mouse_position() - Vector2.ONE * block_size / 2
	coord /= block_size
	coord = coord.floor()
	if coord.x < 0 or coord.x >= get_width() or coord.y < 0 or coord.y >= _char_height:
		return
	if not _mouse_left_pressed and not _mouse_right_pressed:
		return
	_is_filled_arr[coord.y][coord.x] = _mouse_left_pressed or not _mouse_right_pressed
	queue_redraw()
