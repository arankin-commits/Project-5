extends CanvasLayer

const TEXT_AREA := Vector2(685, 80)

const CATALOG := preload("res://scripts/npc_catalog.gd")
signal closed
var active := false
var npc_id := ""
var line_index := 0
var lines: Array = []
var player: CharacterBody2D
var restore_controls := true
var screen: Control
var portrait: Polygon2D
var speaker: Label
var dialogue_text: Label
var next_button: Button
var current_portrait_id := ""

func _ready() -> void:
	layer = 30
	screen = Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	var dim := ColorRect.new()
	dim.color = Color(0.015,0.02,0.025,0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(dim)
	var panel := PanelContainer.new()
	panel.position = Vector2(45,475)
	panel.size = Vector2(1190,215)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("131d22")
	style.border_color = Color("b48b50")
	style.set_border_width_all(2)
	style.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel",style)
	screen.add_child(panel)
	var text_box := VBoxContainer.new()
	text_box.position = Vector2(500,488)
	text_box.size = Vector2(685,185)
	text_box.add_theme_constant_override("separation",12)
	screen.add_child(text_box)
	speaker = Label.new()
	speaker.add_theme_font_size_override("font_size",28)
	speaker.add_theme_color_override("font_color",Color("ffcf82"))
	text_box.add_child(speaker)
	dialogue_text = Label.new()
	dialogue_text.custom_minimum_size = TEXT_AREA
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size",21)
	text_box.add_child(dialogue_text)
	next_button = Button.new()
	next_button.pressed.connect(advance)
	text_box.add_child(next_button)
	screen.hide()

func open(id: String, actor: CharacterBody2D, custom_lines: Array = []) -> void:
	if active:
		return
	npc_id = id
	player = actor
	restore_controls = player.controls_enabled
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	if player.get("visual") != null and player.visual.has_method("play"):
		player.visual.play("idle")
	if custom_lines.size() > 0:
		lines = custom_lines
	else:
		lines = CATALOG.get_lines(id)
	lines = paginate_lines(lines)
	line_index = 0
	current_portrait_id = ""
	active = true
	screen.show()
	_refresh()
	next_button.grab_focus()

func _refresh() -> void:
	if line_index < 0 or line_index >= lines.size():
		return
	var item = lines[line_index]
	var text_content := ""
	var speaker_name := ""
	var portrait_id := npc_id
	
	if item is Dictionary:
		text_content = str(item.get("text", ""))
		speaker_name = str(item.get("speaker", CATALOG.NPCS[npc_id].name if CATALOG.NPCS.has(npc_id) else npc_id)).to_upper()
		portrait_id = str(item.get("portrait", npc_id))
	else:
		text_content = str(item)
		speaker_name = CATALOG.NPCS[npc_id].name.to_upper() if CATALOG.NPCS.has(npc_id) else npc_id.to_upper()
		portrait_id = npc_id
	
	dialogue_text.text = text_content
	speaker.text = speaker_name
	
	if portrait_id != current_portrait_id or not is_instance_valid(portrait):
		if is_instance_valid(portrait):
			portrait.queue_free()
		if CATALOG.NPCS.has(portrait_id):
			portrait = CATALOG.visual(portrait_id, true)
			portrait.scale = Vector2.ONE * 0.46
			portrait.position = Vector2(-200, 180)
			screen.add_child(portrait)
			current_portrait_id = portrait_id
		else:
			current_portrait_id = ""
	
	next_button.text = "Continue [E]" if line_index < lines.size() - 1 else "Leave [E]"

func advance() -> void:
	if not active:
		return
	line_index += 1
	if line_index >= lines.size():
		close()
	else:
		_refresh()

func close() -> void:
	if not active:
		return
	active = false
	screen.hide()
	current_portrait_id = ""
	if is_instance_valid(portrait):
		portrait.queue_free()
		portrait = null
	if is_instance_valid(player):
		player.controls_enabled = restore_controls
	closed.emit()

# Measure the same font, wrapping and line spacing used by the displayed label.
func page_fits(text: String) -> bool:
	var paragraph := TextParagraph.new()
	paragraph.width = TEXT_AREA.x
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	paragraph.add_string(text, dialogue_text.get_theme_font("font"), dialogue_text.get_theme_font_size("font_size"))
	var height := paragraph.get_size().y
	height += maxi(0, paragraph.get_line_count() - 1) * dialogue_text.get_theme_constant("line_spacing")
	return height <= TEXT_AREA.y

func paginate_text(text: String) -> Array[String]:
	var pages: Array[String] = []
	var sentences: Array[String] = []
	var endings := RegEx.new()
	endings.compile("[.!?]+[\"'\u201d\u2019)]*(?:\\s+|$)|\\n+")
	var start := 0
	for ending in endings.search_all(text):
		sentences.append(text.substr(start, ending.get_end() - start))
		start = ending.get_end()
	if start < text.length():
		sentences.append(text.substr(start))
	var page := ""
	for sentence in sentences:
		if page_fits((page + sentence).strip_edges()):
			page += sentence
			continue
		if not page.strip_edges().is_empty():
			pages.append(page.strip_edges())
		page = sentence.strip_edges()
		# A sentence longer than an entire page must still remain readable.
		# Split at word boundaries, or characters for a single oversized word.
		while not page_fits(page):
			var low := 1
			var high := page.length()
			while low < high:
				var middle := (low + high + 1) / 2
				if page_fits(page.left(middle)):
					low = middle
				else:
					high = middle - 1
			var cut := low
			var space := page.rfind(" ", cut - 1)
			if space > 0:
				cut = space + 1
			pages.append(page.left(cut).strip_edges())
			page = page.substr(cut).strip_edges()
		# Keep separation when the next sentence is appended.
		page += " "
	if not page.strip_edges().is_empty() or pages.is_empty():
		pages.append(page.strip_edges())
	return pages

func paginate_lines(source: Array) -> Array:
	var result: Array = []
	for item in source:
		var text := str(item.get("text", "")) if item is Dictionary else str(item)
		for page in paginate_text(text):
			if item is Dictionary:
				var copy: Dictionary = item.duplicate(true)
				copy["text"] = page
				result.append(copy)
			else:
				result.append(page)
	return result
