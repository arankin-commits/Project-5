extends Node

# Room visits never reroll this state. RunConfig.end_run is the sole caller.
const COCKPIT_LAYOUTS := [
	{"pilot": 0, "copilot": 1}, {"pilot": 1, "copilot": 0},
	{"pilot": 0}, {"pilot": 1}, {"copilot": 0}, {"copilot": 1}
]
var cockpit_layout: Dictionary = COCKPIT_LAYOUTS[0].duplicate()
var return_count := 0

func returned_from_run() -> void:
	var choices: Array[Dictionary] = []
	for layout in COCKPIT_LAYOUTS:
		if layout != cockpit_layout:
			choices.append(layout)
	cockpit_layout = choices[randi_range(0, choices.size()-1)].duplicate()
	return_count += 1
