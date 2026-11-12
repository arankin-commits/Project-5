extends Control

signal resume_requested
signal give_up_requested

var page := "menu"
var stack: VBoxContainer
var title: Label
var settings: Node
var can_give_up := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	settings = get_node("/root/GameSettings")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.025, 0.03, 0.9)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 540)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("142126")
	style.border_color = Color("9f7845")
	style.set_border_width_all(2)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)
	hide()

func _page(id: String, heading: String) -> void:
	page = id
	for child in stack.get_children():
		stack.remove_child(child)
		child.queue_free()
	title = Label.new()
	title.text = heading
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("ffdea5"))
	stack.add_child(title)
	show()

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 54
	button.add_theme_font_size_override("font_size", 20)
	button.pressed.connect(action)
	stack.add_child(button)
	return button

func show_menu() -> void:
	_page("menu", "IN-GAME MENU")
	_button("Resume", resume_requested.emit).grab_focus()
	_button("Settings", show_settings)
	_button("Controls", show_controls)
	var give_up := _button("Give Up", give_up_requested.emit)
	give_up.disabled = not can_give_up
	if not can_give_up:
		give_up.tooltip_text = "Give Up is available during a roguelite run."
	_button("Quit", func(): get_tree().quit())

func back() -> void:
	if page == "menu":
		resume_requested.emit()
	else:
		if page == "settings":
			settings.save()
		show_menu()

func show_settings() -> void:
	_page("settings", "SETTINGS")
	var volume_label := Label.new()
	volume_label.text = "Master volume: %d%%" % roundi(settings.volume * 100)
	stack.add_child(volume_label)
	var slider := HSlider.new()
	slider.name = "Volume"
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = settings.volume * 100
	slider.custom_minimum_size.y = 40
	slider.value_changed.connect(func(value: float):
		settings.volume = value / 100.0
		AudioServer.set_bus_volume_linear(0, settings.volume)
		volume_label.text = "Master volume: %d%%" % roundi(value)
	)
	stack.add_child(slider)
	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.text = "Fullscreen"
	fullscreen_toggle.button_pressed = settings.fullscreen
	fullscreen_toggle.toggled.connect(func(enabled: bool):
		settings.fullscreen = enabled
		settings.apply()
	)
	stack.add_child(fullscreen_toggle)
	var shake_toggle := CheckButton.new()
	shake_toggle.text = "Screen shake"
	shake_toggle.button_pressed = settings.screen_shake
	shake_toggle.toggled.connect(func(enabled: bool): settings.screen_shake = enabled)
	stack.add_child(shake_toggle)
	_button("Back", back)
	slider.grab_focus()

func show_controls() -> void:
	_page("controls", "CONTROLS")
	var instructions := Label.new()
	instructions.text = "Move                 WASD / Arrow keys\n\nStrike                Left mouse / J\n\nHeavy strike      Right mouse / K\n\nDash                  Space\n\nInteract              E\n\nGrapple              F\n\nCore burst         Q (25 energy)\n\nMenu / Back      Esc"
	instructions.add_theme_font_size_override("font_size", 17)
	stack.add_child(instructions)
	_button("Back", back).grab_focus()
