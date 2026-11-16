extends CanvasLayer

signal closed
signal song_selected(song_id: String)

const HUD_TEXTURE := preload("res://HUD/Steampunk Jukebox Song Selection.png")
const DESIGN_SIZE := Vector2(1672, 941)
const VIEWPORT_SIZE := Vector2(1280, 720)

const SONGS := [
	{
		"id": "copper_hearth",
		"title": "Copper Hearth",
		"genre": "Grand Fleet Anthem",
		"tempo": "Andante Maestoso",
		"description": "Warm brass overture and stately strings echoing through the grand hall above the clouds.",
		"stream": preload("res://Music/Flying Liberty music.mp3"),
		"pitch": 1.0
	},
	{
		"id": "scribes_of_the_air",
		"title": "Scribes of the Air",
		"genre": "High Altitude Reel",
		"tempo": "Allegro Vivace",
		"description": "A brisk, buoyant cadence capturing navigators and wind gauges charting courses across endless skies.",
		"stream": preload("res://Music/Flying Liberty music.mp3"),
		"pitch": 1.15
	},
	{
		"id": "parlour_clouds",
		"title": "Parlour Above the Clouds",
		"genre": "Aether Salon Waltz",
		"tempo": "Adagio Tranquillo",
		"description": "A tranquil, lingering melody heard when lanterns dim and the skyship drifts in moonlit mists.",
		"stream": preload("res://Music/Flying Liberty music.mp3"),
		"pitch": 0.88
	},
	{
		"id": "captains_quadrille",
		"title": "Captain's Quadrille",
		"genre": "Fleet March",
		"tempo": "Tempo di Marcia",
		"description": "An energetic military march with crisp rhythm, celebrating daring maneuvers of the sky fleet.",
		"stream": preload("res://Music/Boiler area music.mp3"),
		"pitch": 1.08
	},
	{
		"id": "clockwork_pavane",
		"title": "Clockwork Pavane",
		"genre": "Foundry Cadence",
		"tempo": "Moderato Ritmico",
		"description": "Deep reverberating furnace rhythms and steam vents echoing through lower boiler chambers.",
		"stream": preload("res://Music/Boiler area music.mp3"),
		"pitch": 0.92
	},
	{
		"id": "fathers_photograph",
		"title": "Father's Photograph",
		"genre": "Nostalgic Elegy",
		"tempo": "Largo Elegiaco",
		"description": "A poignant, solemn melody carried by cello, remembering the pioneers of bygone expeditions.",
		"stream": preload("res://Music/Flying Liberty music.mp3"),
		"pitch": 0.78
	}
]

var selected_index := 0
var scale_factor := 1.0
var opened_frame := -1

var shade: ColorRect
var console: Control
var background_art: TextureRect

var selection_box: Panel
var selector_arrow: Label
var page_indicator: Label
var marquee_title: Label
var marquee_subtitle: Label
var lever_rect: Control
var lever_pivot: Control

var song_buttons: Array[Button] = []
var playing_badges: Array[Label] = []
var slot_dim_overlays: Array[ColorRect] = []

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func open_jukebox() -> void:
	opened_frame = Engine.get_process_frames()
	var bg_music: Node = get_node_or_null("/root/BackgroundMusic")
	if bg_music != null and bg_music.has_method("get_active_song_id"):
		var active_id: String = bg_music.get_active_song_id()
		for i in SONGS.size():
			if SONGS[i].id == active_id:
				selected_index = i
				break
	_update_selection()
	visible = true

func close_jukebox() -> void:
	visible = false
	closed.emit()

func select_previous() -> void:
	selected_index = (selected_index - 1 + SONGS.size()) % SONGS.size()
	_update_selection()

func select_next() -> void:
	selected_index = (selected_index + 1) % SONGS.size()
	_update_selection()

func play_selected_song() -> void:
	if selected_index < 0 or selected_index >= SONGS.size():
		return
	var song: Dictionary = SONGS[selected_index]
	var bg_music: Node = get_node_or_null("/root/BackgroundMusic")
	if bg_music != null and bg_music.has_method("play_jukebox_song"):
		bg_music.play_jukebox_song(song.stream, song.pitch, song.id)
	song_selected.emit(song.id)
	_animate_lever()
	_update_selection()

func _animate_lever() -> void:
	if lever_pivot == null:
		return
	var tween := create_tween()
	tween.tween_property(lever_pivot, "rotation_degrees", 12.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lever_pivot, "rotation_degrees", 0.0, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if Engine.get_process_frames() == opened_frame:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_E or event.physical_keycode == KEY_E)):
		close_jukebox()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		select_previous()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		select_next()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		play_selected_song()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	scale_factor = VIEWPORT_SIZE.x / DESIGN_SIZE.x

	shade = ColorRect.new()
	shade.color = Color(0.015, 0.01, 0.018, 0.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	console = Control.new()
	console.custom_minimum_size = VIEWPORT_SIZE
	console.size = VIEWPORT_SIZE
	center.add_child(console)

	background_art = TextureRect.new()
	background_art.texture = HUD_TEXTURE
	background_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background_art.size = VIEWPORT_SIZE
	background_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	console.add_child(background_art)

	_build_slot_buttons()
	_build_selection_box()
	_build_arrow_buttons()
	_build_page_indicator()
	_build_lever_area()
	_build_marquee_panel()
	_build_bottom_bar()

func _build_slot_buttons() -> void:
	var slot_x := 460.0 * scale_factor
	var slot_w := 670.0 * scale_factor
	var slot_h := 68.0 * scale_factor

	for i in SONGS.size():
		var slot_y := (250.0 + i * 74.0) * scale_factor

		# Interactive button covering the plaque
		var btn := Button.new()
		btn.name = "SongButton_%d" % i
		btn.flat = true
		btn.position = Vector2(slot_x, slot_y)
		btn.size = Vector2(slot_w, slot_h)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		btn.tooltip_text = "%s\n%s\nTempo: %s" % [SONGS[i].title, SONGS[i].description, SONGS[i].tempo]
		btn.pressed.connect(func(idx := i):
			if selected_index == idx:
				play_selected_song()
			else:
				selected_index = idx
				_update_selection()
		)
		btn.mouse_entered.connect(func(idx := i):
			selected_index = idx
			_update_selection()
		)
		console.add_child(btn)
		song_buttons.append(btn)

		# Playing note badge on the left side of the slot
		var badge := Label.new()
		badge.name = "PlayingBadge_%d" % i
		badge.text = "♫"
		badge.add_theme_font_size_override("font_size", 24)
		badge.add_theme_color_override("font_color", Color("ffe494"))
		badge.position = Vector2(slot_x + 8.0, slot_y + (slot_h - 32.0) / 2.0)
		badge.visible = false
		console.add_child(badge)
		playing_badges.append(badge)

func _build_selection_box() -> void:
	selection_box = Panel.new()
	selection_box.name = "SelectionBox"
	selection_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.85, 0.45, 0.10)
	style.border_color = Color("ffe594")
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.9, 0.65, 0.2, 0.45)
	style.shadow_size = 6
	selection_box.add_theme_stylebox_override("panel", style)
	console.add_child(selection_box)

	selector_arrow = Label.new()
	selector_arrow.name = "SelectorArrow"
	selector_arrow.text = "▶"
	selector_arrow.add_theme_font_size_override("font_size", 22)
	selector_arrow.add_theme_color_override("font_color", Color("ffe594"))
	selector_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	console.add_child(selector_arrow)

func _build_arrow_buttons() -> void:
	var btn_x := 1170.0 * scale_factor
	var btn_w := 90.0 * scale_factor

	# Up button
	var up_btn := Button.new()
	up_btn.name = "UpButton"
	up_btn.flat = true
	up_btn.position = Vector2(btn_x, 280.0 * scale_factor)
	up_btn.size = Vector2(btn_w, 80.0 * scale_factor)
	up_btn.tooltip_text = "Previous Track [Up / W]"
	up_btn.pressed.connect(select_previous)
	console.add_child(up_btn)

	# Down button
	var down_btn := Button.new()
	down_btn.name = "DownButton"
	down_btn.flat = true
	down_btn.position = Vector2(btn_x, 515.0 * scale_factor)
	down_btn.size = Vector2(btn_w, 80.0 * scale_factor)
	down_btn.tooltip_text = "Next Track [Down / S]"
	down_btn.pressed.connect(select_next)
	console.add_child(down_btn)

func _build_page_indicator() -> void:
	# Subtle dark backing covering pre-baked "1 / 6" (x: 1180..1270, y: 420..495 in 1672x941)
	var plate := Panel.new()
	plate.name = "PageIndicatorPlate"
	plate.position = Vector2(1178.0 * scale_factor, 418.0 * scale_factor)
	plate.size = Vector2(92.0 * scale_factor, 78.0 * scale_factor)
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color("382921")
	pstyle.border_color = Color("5c4230")
	pstyle.set_border_width_all(1)
	pstyle.set_corner_radius_all(4)
	plate.add_theme_stylebox_override("panel", pstyle)
	console.add_child(plate)

	page_indicator = Label.new()
	page_indicator.name = "PageIndicator"
	page_indicator.text = "1 / 6"
	page_indicator.position = plate.position
	page_indicator.size = plate.size
	page_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_indicator.add_theme_font_size_override("font_size", 26)
	page_indicator.add_theme_color_override("font_color", Color("f4dcaf"))
	page_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	console.add_child(page_indicator)

func _build_lever_area() -> void:
	lever_pivot = Control.new()
	lever_pivot.name = "LeverPivot"
	lever_pivot.position = Vector2(1340.0 * scale_factor, 800.0 * scale_factor)
	console.add_child(lever_pivot)

	var lever_btn := Button.new()
	lever_btn.name = "LeverButton"
	lever_btn.flat = true
	lever_btn.position = Vector2(1220.0 * scale_factor, 670.0 * scale_factor)
	lever_btn.size = Vector2(190.0 * scale_factor, 180.0 * scale_factor)
	lever_btn.tooltip_text = "Engage Lever — Play Selected Track [Enter]"
	lever_btn.pressed.connect(play_selected_song)
	console.add_child(lever_btn)

func _build_marquee_panel() -> void:
	var panel := PanelContainer.new()
	panel.name = "MarqueePanel"
	panel.position = Vector2(245.0 * scale_factor, 712.0 * scale_factor)
	panel.custom_minimum_size = Vector2(635.0 * scale_factor, 50.0 * scale_factor)
	panel.size = panel.custom_minimum_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.065, 0.075, 0.94)
	style.border_color = Color("c8994d")
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 4
	panel.add_theme_stylebox_override("panel", style)
	console.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	marquee_title = Label.new()
	marquee_title.name = "MarqueeTitle"
	marquee_title.add_theme_font_size_override("font_size", 16)
	marquee_title.add_theme_color_override("font_color", Color("ffe494"))
	vbox.add_child(marquee_title)

	marquee_subtitle = Label.new()
	marquee_subtitle.name = "MarqueeSubtitle"
	marquee_subtitle.add_theme_font_size_override("font_size", 12)
	marquee_subtitle.add_theme_color_override("font_color", Color("dfc8a0"))
	vbox.add_child(marquee_subtitle)

func _build_bottom_bar() -> void:
	var bar_y := 840.0 * scale_factor
	var bar_h := 50.0 * scale_factor

	# Nav button
	var nav_btn := Button.new()
	nav_btn.name = "NavButton"
	nav_btn.flat = true
	nav_btn.position = Vector2(280.0 * scale_factor, bar_y)
	nav_btn.size = Vector2(280.0 * scale_factor, bar_h)
	nav_btn.tooltip_text = "Navigate Songs [Arrow Keys or W/S]"
	nav_btn.pressed.connect(select_next)
	console.add_child(nav_btn)

	# Select button
	var select_btn := Button.new()
	select_btn.name = "SelectButton"
	select_btn.flat = true
	select_btn.position = Vector2(630.0 * scale_factor, bar_y)
	select_btn.size = Vector2(230.0 * scale_factor, bar_h)
	select_btn.tooltip_text = "Select & Play Track [Enter / Space]"
	select_btn.pressed.connect(play_selected_song)
	console.add_child(select_btn)

	# Play button
	var play_btn := Button.new()
	play_btn.name = "PlayButton"
	play_btn.flat = true
	play_btn.position = Vector2(630.0 * scale_factor, bar_y)
	play_btn.size = Vector2(230.0 * scale_factor, bar_h)
	play_btn.tooltip_text = "Play Track [Enter / Space]"
	play_btn.pressed.connect(play_selected_song)
	console.add_child(play_btn)

	# Back button
	var back_btn := Button.new()
	back_btn.name = "BackButton"
	back_btn.flat = true
	back_btn.position = Vector2(1220.0 * scale_factor, bar_y)
	back_btn.size = Vector2(165.0 * scale_factor, bar_h)
	back_btn.tooltip_text = "Return to Main Hall [E / Esc]"
	back_btn.pressed.connect(close_jukebox)
	console.add_child(back_btn)

func _update_selection() -> void:
	if selection_box == null:
		return

	var slot_x := 460.0 * scale_factor
	var slot_w := 670.0 * scale_factor
	var slot_h := 68.0 * scale_factor
	var slot_y := (250.0 + selected_index * 74.0) * scale_factor

	selection_box.position = Vector2(slot_x, slot_y)
	selection_box.size = Vector2(slot_w, slot_h)

	selector_arrow.position = Vector2(slot_x - 30.0, slot_y + (slot_h - 26.0) / 2.0)

	page_indicator.text = "%d / %d" % [selected_index + 1, SONGS.size()]

	var active_id := ""
	var bg_music: Node = get_node_or_null("/root/BackgroundMusic")
	if bg_music != null and bg_music.has_method("get_active_song_id"):
		active_id = bg_music.get_active_song_id()

	for i in playing_badges.size():
		var is_curr_playing: bool = (SONGS[i].id == active_id)
		playing_badges[i].visible = is_curr_playing

	var song: Dictionary = SONGS[selected_index]
	var status_prefix := "▶ PLAYING: " if song.id == active_id else "SELECTED: "
	marquee_title.text = "%s%s — %s" % [status_prefix, song.title, song.genre]
	marquee_subtitle.text = "%s | Tempo: %s" % [song.description, song.tempo]
