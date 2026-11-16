extends RefCounted

static func style(fill := Color("241b14"), border := Color("b67e39")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(2)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(12)
	return box

static func button(parent: Node, text: String, rect: Rect2, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_color_override("font_color", Color("ffe2ad"))
	b.add_theme_stylebox_override("normal", style())
	b.add_theme_stylebox_override("hover", style(Color("53361b"), Color("ffce78")))
	b.add_theme_stylebox_override("pressed", style(Color("135254"), Color("65e2df")))
	b.add_theme_stylebox_override("focus", style(Color(0,0,0,0), Color("80eeea")))
	b.pressed.connect(action)
	parent.add_child(b)
	return b

static func picture(parent: Node, path: String, rect: Rect2, crop := Rect2()) -> TextureRect:
	var t := TextureRect.new()
	var texture: Texture2D = load(path)
	if crop.has_area():
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = crop
		texture = atlas
	t.texture = texture
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.position = rect.position
	t.size = rect.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(t)
	return t

static func label(parent: Node, text: String, rect: Rect2, font_size := 22) -> Label:
	var l := Label.new()
	l.text = text
	l.position = rect.position
	l.size = rect.size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("ffe2ad"))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

static func fit(canvas: Control, viewport: Vector2, design := Vector2(1280,720)) -> void:
	var factor := minf(viewport.x / design.x, viewport.y / design.y)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (viewport - design * factor) / 2
