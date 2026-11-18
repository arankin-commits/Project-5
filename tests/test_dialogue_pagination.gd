extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var dialogue = load("res://scripts/npc_dialogue.gd").new()
	root.add_child(dialogue)
	var sentence := "The engines are steady and the crew is ready to depart. "
	var source := sentence.repeat(14).strip_edges()
	var pages: Array = dialogue.paginate_text(source)
	check(pages.size() > 1, "Long dialogue did not paginate")
	check(" ".join(pages) == source, "Dialogue text lost or reordered")
	for page in pages:
		check(dialogue.page_fits(page), "Page exceeds text area")
		check(str(page).ends_with("."), "Fitting sentence was split")
	for long_text in ["longword ".repeat(150).strip_edges(), "W".repeat(1000)]:
		var long_pages: Array = dialogue.paginate_text(long_text)
		check(long_pages.size() > 1, "Oversized sentence did not paginate")
		check("".join(long_pages).replace(" ", "") == long_text.replace(" ", ""), "Oversized text lost")
		for page in long_pages:
			check(dialogue.page_fits(page), "Oversized sentence page exceeds area")
	var actor = load("res://scripts/cockpit_player.gd").new()
	root.add_child(actor)
	var entry := {"speaker":"Engineer", "portrait":"engineer", "text":source}
	dialogue.open("engineer",actor,[entry])
	check(entry.text == source, "Original dialogue mutated")
	for i in dialogue.lines.size():
		check(dialogue.lines[i].speaker == "Engineer" and dialogue.lines[i].portrait == "engineer", "Continuation lost speaker or portrait")
		check(not actor.controls_enabled, "Controls unlocked mid-conversation")
		await process_frame
		check(dialogue.dialogue_text.get_line_count() * dialogue.dialogue_text.get_line_height() <= 80, "Rendered text exceeds height")
		check(dialogue.next_button.text == ("Leave [E]" if i == dialogue.lines.size()-1 else "Continue [E]"), "Incorrect continuation button")
		dialogue.advance()
	check(not dialogue.active and actor.controls_enabled, "Conversation did not restore controls")
	print("DIALOGUE_PAGINATION_FAILURES=",failures)
	dialogue.free()
	actor.free()
	quit(1 if failures else 0)
