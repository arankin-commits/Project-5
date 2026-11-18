class_name CardChoiceButton
extends Button

# ==============================================================================
# CARD CHOICE BUTTON
# Renders a high-fidelity elemental card matching the steampunk card HUD reference.
# Features rarity-themed metallic frames, elemental crest badges, illustration viewports,
# elegant serif typography, stat damage panels, and golden corner bracket hover glows.
# ==============================================================================

const ElementalCards := preload("res://scripts/elemental_cards.gd")

const RARITY_COLORS: Dictionary = {
	"common": {
		"border": Color("64748b"),
		"glow": Color("94a3b8"),
		"badge_bg": Color("334155"),
		"text": Color("f1f5f9")
	},
	"rare": {
		"border": Color("2563eb"),
		"glow": Color("38bdf8"),
		"badge_bg": Color("1e3a8a"),
		"text": Color("60a5fa")
	},
	"epic": {
		"border": Color("9333ea"),
		"glow": Color("c084fc"),
		"badge_bg": Color("581c87"),
		"text": Color("e9d5ff")
	},
	"legendary": {
		"border": Color("f59e0b"),
		"glow": Color("fde047"),
		"badge_bg": Color("78350f"),
		"text": Color("fef08a")
	}
}

var choice_data: Dictionary = {}
var rarity: String = "common"
var element: String = ""
var is_hovered: bool = false
var base_y: float = 0.0

var art_rect: TextureRect
var crest_rect: TextureRect
var rarity_badge: PanelContainer
var rarity_label: Label
var title_label: Label
var desc_label: Label
var mini_icon_rect: TextureRect
var stat_primary_label: Label
var stat_secondary_label: Label

func _init(data: Dictionary = {}) -> void:
	choice_data = data
	custom_minimum_size = Vector2(310, 480)
	size = Vector2(310, 480)
	flat = true
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	rarity = str(choice_data.get("rarity", "common")).to_lower()
	if not RARITY_COLORS.has(rarity):
		rarity = "common"
	element = str(choice_data.get("element", "")).to_lower()
	_build_ui()

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	base_y = position.y

func _build_ui() -> void:
	# 1. Art Illustration Window
	art_rect = TextureRect.new()
	art_rect.name = "ArtWindow"
	art_rect.position = Vector2(15, 33)
	art_rect.size = Vector2(280, 168)
	art_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_rect.texture = _resolve_art_texture()
	add_child(art_rect)

	# 2. Top-Left Elemental Crest Badge
	crest_rect = TextureRect.new()
	crest_rect.name = "ElementCrest"
	crest_rect.position = Vector2(6, 6)
	crest_rect.size = Vector2(46, 46)
	crest_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crest_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crest_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crest_rect.texture = _resolve_crest_texture()
	add_child(crest_rect)

	# 3. Top Rarity Ribbon / Pill Badge
	rarity_badge = PanelContainer.new()
	rarity_badge.name = "RarityBadge"
	rarity_badge.position = Vector2(85, -10)
	rarity_badge.size = Vector2(140, 24)
	rarity_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var r_colors: Dictionary = RARITY_COLORS[rarity]
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = r_colors["badge_bg"]
	badge_style.border_color = r_colors["glow"]
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(12)
	badge_style.content_margin_top = 2
	badge_style.content_margin_bottom = 2
	badge_style.content_margin_left = 12
	badge_style.content_margin_right = 12
	rarity_badge.add_theme_stylebox_override("panel", badge_style)
	
	rarity_label = Label.new()
	rarity_label.text = rarity.to_upper()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", r_colors["text"])
	rarity_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	rarity_label.add_theme_constant_override("shadow_offset_x", 1)
	rarity_label.add_theme_constant_override("shadow_offset_y", 1)
	rarity_badge.add_child(rarity_label)
	add_child(rarity_badge)

	# 4. Card Title
	title_label = Label.new()
	title_label.name = "CardTitle"
	title_label.position = Vector2(8, 212)
	title_label.size = Vector2(294, 30)
	var card_id: String = str(choice_data.get("id", ""))
	var display_title: String = str(choice_data.get("name", "UPGRADE"))
	if card_id in ["hull", "repair", "max_hp_increase"]:
		display_title = "Reinforced Chassis"
	elif ElementalCards.CARDS.has(card_id):
		display_title = str(ElementalCards.CARDS[card_id].get("name", display_title))
	elif display_title == display_title.to_upper():
		display_title = display_title.capitalize()
	title_label.text = display_title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color("fff3cf"))
	title_label.add_theme_color_override("font_shadow_color", Color("0a0a0a"))
	title_label.add_theme_constant_override("shadow_offset_x", 1)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_label)

	# 5. Card Description
	desc_label = Label.new()
	desc_label.name = "CardDescription"
	desc_label.position = Vector2(16, 252)
	desc_label.size = Vector2(278, 122)
	desc_label.text = _resolve_clean_description()
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color("cbd5e1"))
	desc_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	desc_label.add_theme_constant_override("shadow_offset_x", 1)
	desc_label.add_theme_constant_override("shadow_offset_y", 1)
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(desc_label)

	# 6. Bottom Stat / Damage Panel
	mini_icon_rect = TextureRect.new()
	mini_icon_rect.name = "MiniIcon"
	mini_icon_rect.position = Vector2(24, 410)
	mini_icon_rect.size = Vector2(30, 30)
	mini_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mini_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mini_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mini_icon_rect.texture = _resolve_mini_icon_texture()
	add_child(mini_icon_rect)

	stat_primary_label = Label.new()
	stat_primary_label.name = "StatPrimary"
	stat_primary_label.position = Vector2(64, 393)
	stat_primary_label.size = Vector2(226, 22)
	stat_primary_label.text = _resolve_primary_stat()
	stat_primary_label.add_theme_font_size_override("font_size", 13)
	stat_primary_label.add_theme_color_override("font_color", Color("ffffff"))
	stat_primary_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stat_primary_label.add_theme_constant_override("shadow_offset_x", 1)
	stat_primary_label.add_theme_constant_override("shadow_offset_y", 1)
	stat_primary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stat_primary_label)

	stat_secondary_label = Label.new()
	stat_secondary_label.name = "StatSecondary"
	stat_secondary_label.position = Vector2(64, 416)
	stat_secondary_label.size = Vector2(226, 46)
	stat_secondary_label.text = _resolve_secondary_stat()
	stat_secondary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stat_secondary_label.add_theme_font_size_override("font_size", 11)
	stat_secondary_label.add_theme_color_override("font_color", Color("94a3b8"))
	stat_secondary_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stat_secondary_label.add_theme_constant_override("shadow_offset_x", 1)
	stat_secondary_label.add_theme_constant_override("shadow_offset_y", 1)
	stat_secondary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stat_secondary_label)

func _resolve_art_texture() -> Texture2D:
	var card_id: String = str(choice_data.get("id", "")).to_lower()
	# Check specific cards first
	if card_id == "lightning_attack" and ResourceLoader.exists("res://art/card_hud/art_lightning_attack.png"):
		return load("res://art/card_hud/art_lightning_attack.png")
	elif card_id == "fire_slam" and ResourceLoader.exists("res://art/card_hud/art_fire_slam.png"):
		return load("res://art/card_hud/art_fire_slam.png")
	elif card_id == "ice_slam" and ResourceLoader.exists("res://art/card_hud/art_ice_slam.png"):
		return load("res://art/card_hud/art_ice_slam.png")
	
	# Check elemental archetype textures
	var elem: String = element if not element.is_empty() else "core"
	var action := "generic"
	if card_id.contains("dash"): action = "dash"
	elif card_id.contains("armor") or card_id.contains("shield") or card_id.contains("hull") or card_id.contains("hp") or card_id.contains("repair"): action = "armor"
	elif card_id.contains("attack") or card_id.contains("special") or card_id.contains("strike"): action = "attack"
	elif card_id.contains("slam"): action = "slam"
	
	var specific_path := "res://art/card_hud/art_%s_%s.png" % [elem, action]
	if ResourceLoader.exists(specific_path):
		return load(specific_path)
	var generic_path := "res://art/card_hud/art_%s_generic.png" % elem
	if ResourceLoader.exists(generic_path):
		return load(generic_path)
	if ResourceLoader.exists("res://art/card_hud/art_core_generic.png"):
		return load("res://art/card_hud/art_core_generic.png")
	return null

func _resolve_crest_texture() -> Texture2D:
	var elem: String = element if not element.is_empty() else "core"
	var path := "res://art/card_hud/crest_%s.png" % elem
	if ResourceLoader.exists(path):
		return load(path)
	if ResourceLoader.exists("res://art/card_hud/crest_lightning.png"):
		return load("res://art/card_hud/crest_lightning.png")
	return null

func _resolve_mini_icon_texture() -> Texture2D:
	var elem: String = element if not element.is_empty() else "core"
	var path := "res://art/card_hud/mini_%s.png" % elem
	if ResourceLoader.exists(path):
		return load(path)
	if ResourceLoader.exists("res://art/card_hud/mini_lightning.png"):
		return load("res://art/card_hud/mini_lightning.png")
	return null

func _resolve_clean_description() -> String:
	var card_id: String = str(choice_data.get("id", ""))
	if card_id == "lightning_attack":
		return "Normal attacks now do lightning damage."
	elif card_id == "fire_slam":
		return "Ground Slam produces a ring of fire that expands outwards and burns enemies it passes through."
	elif card_id == "ice_slam":
		return "Ground Slam creates ice pillars around enemies caught in its area, temporarily trapping them."
	elif card_id in ["max_hp_increase", "hull", "repair"]:
		return "+25 maximum hull\nRepair 25 hull"
	elif card_id == "power":
		return "+20% strike damage"
	elif card_id == "dash":
		return "15% faster dash recharge"
	elif card_id == "speed":
		return "+10% movement speed"
	
	# Lookup in ElementalCards catalog if present
	if typeof(ElementalCards) != TYPE_NIL and ElementalCards.CARDS.has(card_id):
		var c: Dictionary = ElementalCards.CARDS[card_id]
		return str(c.get("description", choice_data.get("description", "")))
	
	var raw_desc: String = str(choice_data.get("description", ""))
	var lines := raw_desc.split("\n")
	var cleaned: Array[String] = []
	for l in lines:
		var line_str := l.strip_edges()
		if not line_str.begins_with("[") or not line_str.ends_with("]"):
			cleaned.append(line_str)
	return "\n".join(cleaned)

func _resolve_primary_stat() -> String:
	var card_id: String = str(choice_data.get("id", ""))
	if card_id == "lightning_attack":
		return "+8 / +8 / +12"
	elif card_id == "fire_slam":
		return "18 Fire Damage"
	elif card_id == "ice_slam":
		return "22 Ice Damage"
	elif card_id in ["max_hp_increase", "hull", "repair"]:
		return "+25 Maximum Hull"
	elif card_id == "cds":
		return "Collectible Theme Record"
	elif card_id == "core_xp":
		return "+100 Core XP"
	elif card_id == "aether_cores":
		return "+1 Aether Gear"
	elif card_id == "power":
		return "+20% Strike Damage"
	elif card_id == "dash":
		return "+15% Dash Recharge"
	elif card_id == "speed":
		return "+10% Movement Speed"
	
	if typeof(ElementalCards) != TYPE_NIL and ElementalCards.CARDS.has(card_id):
		var c: Dictionary = ElementalCards.CARDS[card_id]
		var dmg = str(c.get("damage", "")).strip_edges()
		if not dmg.is_empty():
			if dmg.contains("/"):
				return "+%s" % dmg
			elif dmg.is_valid_float() or dmg.is_valid_int():
				return "%s %s Damage" % [dmg, element.capitalize()]
			return dmg
	
	return "%s Power" % (element.capitalize() if not element.is_empty() else "Core Upgrade")

func _resolve_secondary_stat() -> String:
	var card_id: String = str(choice_data.get("id", ""))
	if card_id == "lightning_attack":
		return "Lightning Damage\n(per combo hit)"
	elif card_id == "fire_slam":
		return "+ Applies Burn\n(6 dmg/s for 3s)"
	elif card_id == "ice_slam":
		return "+ Traps for 2s"
	elif card_id in ["max_hp_increase", "hull", "repair"]:
		return "+ Repair 25 Hull"
	elif card_id == "cds":
		return "+ 20% faster dash recharge"
	elif card_id == "core_xp":
		return "+ Permanent skill tree progression"
	elif card_id == "aether_cores":
		return "+ Workshop crafting token"
	elif card_id == "power":
		return "+ Increased strike damage"
	elif card_id == "dash":
		return "+ Faster dash recharge"
	elif card_id == "speed":
		return "+ Faster movement speed"
	
	if typeof(ElementalCards) != TYPE_NIL and ElementalCards.CARDS.has(card_id):
		var c: Dictionary = ElementalCards.CARDS[card_id]
		var dmg = str(c.get("damage", "")).strip_edges()
		var eff = str(c.get("effect", "")).strip_edges()
		if not dmg.is_empty() and not eff.is_empty():
			if eff.to_lower().contains("burn"):
				return "+ Applies Burn"
			elif eff.to_lower().contains("wet"):
				return "+ Applies Wet"
			elif eff.to_lower().contains("freeze") or eff.to_lower().contains("trap"):
				return "+ Freezes / Traps"
			elif eff.to_lower().contains("knockback"):
				return "+ Knockback"
			elif eff.to_lower().contains("chain") or eff.to_lower().contains("spread"):
				return "+ Chains to nearby enemies"
			elif eff.to_lower().contains("armor") or eff.to_lower().contains("retaliate"):
				return "+ Retaliation damage"
			else:
				return "%s Damage" % element.capitalize()
		elif not eff.is_empty():
			return eff
	
	return ""

func _on_mouse_entered() -> void:
	grab_focus()

func _on_mouse_exited() -> void:
	pass

func _on_focus_entered() -> void:
	is_hovered = true
	pivot_offset = size * 0.5
	z_index = 2
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", base_y - 8.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _on_focus_exited() -> void:
	is_hovered = false
	pivot_offset = size * 0.5
	z_index = 0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", base_y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var r_colors: Dictionary = RARITY_COLORS.get(rarity, RARITY_COLORS["common"])
	
	# 1. Outer Glow when Focused / Hovered
	if is_hovered:
		# Luminous golden halo behind card
		draw_rect(Rect2(-8, -8, w + 16, h + 16), Color(1.0, 0.78, 0.2, 0.35), false, 10.0)
		draw_rect(Rect2(-4, -4, w + 8, h + 8), Color(1.0, 0.9, 0.35, 0.5), false, 4.0)

	# 2. Main Card Body Background (Dark Brushed Slate)
	var card_rect := Rect2(0, 0, w, h)
	draw_rect(card_rect, Color("0b0e14"))
	draw_rect(Rect2(2, 2, w - 4, h - 4), Color("121822"))

	# 3. Metallic Border (Rarity Themed or Glowing Selection)
	var border_col: Color = Color("facc15") if is_hovered else r_colors["border"]
	var glow_col: Color = Color("fef08a") if is_hovered else r_colors["glow"]
	draw_rect(card_rect, border_col, false, 2.5)
	draw_rect(Rect2(1, 1, w - 2, h - 2), glow_col, false, 1.0)

	# 4. Golden Corner Brackets when Selected (Matches Card 2 in reference)
	if is_hovered:
		var b_col := Color("fef08a")
		var b_len := 22.0
		var b_thick := 3.5
		# Top-Left
		draw_line(Vector2(0, b_len), Vector2(0, 0), b_col, b_thick)
		draw_line(Vector2(0, 0), Vector2(b_len, 0), b_col, b_thick)
		# Top-Right
		draw_line(Vector2(w - b_len, 0), Vector2(w, 0), b_col, b_thick)
		draw_line(Vector2(w, 0), Vector2(w, b_len), b_col, b_thick)
		# Bottom-Left
		draw_line(Vector2(0, h - b_len), Vector2(0, h), b_col, b_thick)
		draw_line(Vector2(0, h), Vector2(b_len, h), b_col, b_thick)
		# Bottom-Right
		draw_line(Vector2(w - b_len, h), Vector2(w, h), b_col, b_thick)
		draw_line(Vector2(w, h), Vector2(w, h - b_len), b_col, b_thick)

	# 5. Art Viewport Inset Frame
	draw_rect(Rect2(14, 32, 282, 170), Color("1e293b"), false, 1.5)

	# 6. Title Dividing Line
	draw_line(Vector2(35, 246), Vector2(w - 35, 246), Color("85612d"), 1.5)

	# 7. Bottom Stat Box Inset Panel
	var stat_rect := Rect2(12, 385, 286, 82)
	draw_rect(stat_rect, Color("080b10"))
	draw_rect(stat_rect, Color("1e293b"), false, 1.5)
