extends CanvasLayer

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
	dialogue_text.custom_minimum_size = Vector2(685,80)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.add_theme_font_size_override("font_size",21)
	text_box.add_child(dialogue_text)
	next_button = Button.new()
	next_button.pressed.connect(advance)
	text_box.add_child(next_button)
	screen.hide()

func open(id: String, actor: CharacterBody2D) -> void:
	if active:
		return
	npc_id = id
	player = actor
	restore_controls = player.controls_enabled
	player.controls_enabled = false
	player.velocity = Vector2.ZERO
	player.visual.play("idle")
	lines = CATALOG.NPCS[id].lines
	line_index = 0
	if is_instance_valid(portrait):
		portrait.queue_free()
	portrait = CATALOG.visual(id,true)
	portrait.scale = Vector2.ONE * 0.46
	portrait.position = Vector2(-200,180)
	screen.add_child(portrait)
	speaker.text = CATALOG.NPCS[id].name.to_upper()
	active = true
	screen.show()
	_refresh()
	next_button.grab_focus()

func _refresh() -> void:
	dialogue_text.text = lines[line_index]
	next_button.text = "Continue [E]" if line_index < lines.size()-1 else "Leave [E]"

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
	if is_instance_valid(player):
		player.controls_enabled = restore_controls
	closed.emit()
