@tool
extends Container


@export var background_color := Color.OLD_LACE:
	set(value):
		background_color = value
		if not is_node_ready():
			await ready
		back_ground.color = value
@export var half_width_size := Vector2i(8, 16)
@export var full_width_size := Vector2i(16, 16)


var block_size := 30:
	set(value):
		block_size = value
		_resize()


var _image_texture_background := ImageTexture.new()
var _image_texture_black := ImageTexture.new()


@onready var back_ground: ColorRect = %BackGround
@onready var margin_container_1: MarginContainer = %MarginContainer1
@onready var color_rect: ColorRect = %ColorRect
@onready var h_box_container: HBoxContainer = %HBoxContainer


func _ready() -> void:
	back_ground.color = background_color

	var image_background := Image.new()
	image_background.set_data(1, 1, false, Image.FORMAT_RGB8, [0, 0, 0])
	image_background.set_pixel(0, 0, background_color)
	_image_texture_background.set_image(image_background)

	var image_black := Image.new()
	image_black.set_data(1, 1, false, Image.FORMAT_RGB8, [0, 0, 0])
	image_black.set_pixel(0, 0, Color.BLACK)
	_image_texture_black.set_image(image_black)

	_resize()


func add(type: String) -> void:
	var width := 0
	var height := half_width_size.y
	if type == "half":
		width = half_width_size.x
	elif type == "full":
		width = full_width_size.x

	var _margin_container1 := MarginContainer.new()
	_margin_container1.add_theme_constant_override("margin_left", 3)
	_margin_container1.add_theme_constant_override("margin_top", 3)
	_margin_container1.add_theme_constant_override("margin_right", 3)
	_margin_container1.add_theme_constant_override("margin_bottom", 3)
	h_box_container.add_child(_margin_container1)
	var _v_box_container1 := VBoxContainer.new()
	_v_box_container1.add_theme_constant_override("separation", 1)
	_margin_container1.add_child(_v_box_container1)
	for y in range(height):
		var _h_box_container1 := HBoxContainer.new()
		_h_box_container1.add_theme_constant_override("separation", 1)
		_v_box_container1.add_child(_h_box_container1)
		for x in range(width):
			var _texture_button1 := TextureButton.new()
			_texture_button1.custom_minimum_size = Vector2i.ONE * block_size
			_texture_button1.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
			_texture_button1.name = "%d %d" % [y, x]
			_texture_button1.stretch_mode = TextureButton.STRETCH_SCALE
			_texture_button1.texture_normal = _image_texture_background
			_texture_button1.add_to_group("_texture_buttons")
			_texture_button1.pressed.connect(func ():
				if _texture_button1.texture_normal.get_image().get_pixel(0, 0) == Color.BLACK:
					_texture_button1.texture_normal = _image_texture_background
				else:
					_texture_button1.texture_normal = _image_texture_black
			)
			_h_box_container1.add_child(_texture_button1)
	_resize()


func delete() -> void:
	if h_box_container.get_children().size() == 0:
		return
	h_box_container.remove_child(h_box_container.get_children()[-1])
	_resize()


func _resize() -> void:
	if not is_node_ready():
		await ready
	margin_container_1.add_theme_constant_override("margin_left", block_size / 2.0 - 3)
	margin_container_1.add_theme_constant_override("margin_top", block_size / 2.0 - 3)
	margin_container_1.add_theme_constant_override("margin_right", block_size / 2.0 - 3)
	margin_container_1.add_theme_constant_override("margin_bottom", block_size / 2.0 - 3)
	for _texture_button in get_tree().get_nodes_in_group("_texture_buttons"):
		_texture_button.custom_minimum_size = Vector2i.ONE * block_size
