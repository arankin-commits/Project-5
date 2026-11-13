extends RefCounted

const NPCS := {
	"pilot": {"name":"Pilot", "file":"Pilot", "anchor":Vector2(205,965), "scale":0.13, "key_black":true, "split":[Vector2(490,0),Vector2(490,350),Vector2(385,650),Vector2(360,1086)], "lines":["Engines steady. We will keep the Flying Liberty in the air while you are down there.", "Come back in one piece. I would rather fly you home than recover your signal."]},
	"copilot": {"name":"Copilot", "file":"Copilot", "anchor":Vector2(200,960), "scale":0.13, "split":[Vector2(390,0),Vector2(390,700),Vector2(315,900),Vector2(315,1086)], "lines":["Charts checked, weather logged. There is always another route if the first one closes.", "The pilot watches the horizon. I watch everything he misses."]},
	"handler": {"name":"Handler", "file":"Handler", "anchor":Vector2(290,1015), "scale":0.13, "split":[Vector2(490,0),Vector2(490,1086)], "lines":["Your signal is stable. The sync chamber will bring you back when the run ends.", "Review your loadout before you reconnect. Preparation is the part we can control."]},
	"cook": {"name":"Cook", "file":"Cook", "anchor":Vector2(250,1015), "scale":0.13, "key_black":true, "split":[Vector2(470,0),Vector2(470,1086)], "lines":["Sit down when you get a chance. Nobody does their best work on an empty stomach.", "And tell the kids the next batch needs time. They keep trying to negotiate with the oven."]},
	"kids": {"name":"Kids", "file":"Kids", "anchor":Vector2(210,785), "scale":0.18, "split":[Vector2(420,0),Vector2(420,700),Vector2(375,860),Vector2(350,1086)], "lines":["Did you see any enormous robots? Bigger than the ship?", "We saved you a bite. Well... we were going to."]},
	"old_man": {"name":"Sleeping Old Man", "file":"Sleeping old man", "anchor":Vector2(300,825), "scale":0.23, "split":[Vector2(620,0),Vector2(620,470),Vector2(560,620),Vector2(420,830),Vector2(350,1086)], "lines":["...Hmm? If the ship is still flying, it can wait.", "Wake me when the tea is ready. Not before."]},
	"engineer": {"name":"Engineer", "file":"engineer", "anchor":Vector2(250,980), "scale":0.16, "split":[Vector2(470,0),Vector2(470,530),Vector2(390,680),Vector2(390,1086)], "lines":["Every system has a weak point. My job is to find ours before someone else does.", "The skill terminal is ready. Bring back salvage and we can make your next run better."]},
	"mechanic": {"name":"Mechanic", "file":"Mechanic", "anchor":Vector2(230,980), "scale":0.15, "key_black":true, "split":[Vector2(420,0),Vector2(420,540),Vector2(395,1086)], "lines":["Something rattling? Bring it here. If it is not rattling, I can probably improve it anyway.", "Leave the heavy lifting to me. You concentrate on making it back."]},
	"cyber_security": {"name":"Cyber Security Analyst", "file":"Cyber Security", "anchor":Vector2(230,1025), "scale":0.13, "split":[Vector2(430,0),Vector2(430,730),Vector2(365,900),Vector2(365,1086)], "lines":["The ship's network is secure."]},
	"info_broker": {"name":"Info Broker", "file":"Info Broker", "anchor":Vector2(235,845), "scale":0.15, "split":[Vector2(460,0),Vector2(460,1086)], "lines":["Information has a way of finding its audience."]}
}

static func visual(id: String, portrait := false) -> Polygon2D:
	var data: Dictionary = NPCS[id]
	var points := PackedVector2Array()
	if portrait:
		for point in data.split:
			points.append(point)
		points.append(Vector2(1448,1086))
		points.append(Vector2(1448,0))
	else:
		points.append(Vector2.ZERO)
		for point in data.split:
			points.append(point)
		points.append(Vector2(0,1086))
	var art := Polygon2D.new()
	art.texture = load("res://characters/NPCS/" + data.file + ".png")
	art.polygon = points
	art.uv = points
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if data.get("key_black", false):
		# These three supplied sheets are RGB; key their black matte at draw time.
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; void fragment(){vec4 c=texture(TEXTURE,UV); c.a*=smoothstep(0.005,0.035,max(c.r,max(c.g,c.b))); COLOR=c;}"
		var material := ShaderMaterial.new()
		material.shader = shader
		art.material = material
	return art
