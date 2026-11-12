extends Node

const SAVE_PATH := "user://settings.cfg"
var volume := 0.8
var fullscreen := false
var screen_shake := true

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		volume = clampf(float(config.get_value("game", "volume", 0.8)), 0.0, 1.0)
		fullscreen = bool(config.get_value("game", "fullscreen", false))
		screen_shake = bool(config.get_value("game", "screen_shake", true))
	apply()

func apply() -> void:
	AudioServer.set_bus_volume_linear(0, volume)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func save() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "volume", volume)
	config.set_value("game", "fullscreen", fullscreen)
	config.set_value("game", "screen_shake", screen_shake)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save settings: %s" % error_string(error))
