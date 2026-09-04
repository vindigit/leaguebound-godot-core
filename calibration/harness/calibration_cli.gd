class_name CalibrationCli
extends RefCounted

## Minimal `--key=value` parsing for the calibration runners.
##
## Every runner takes its sample count from the command line so the same
## committed tool serves the PR smoke gate, the nightly suite, and the
## pre-release deep run without three copies of the harness drifting apart.


static func parse(arguments: PackedStringArray) -> Dictionary:
	var options: Dictionary = {}
	for argument in arguments:
		var text: String = argument
		if text.begins_with("--"):
			text = text.substr(2)
		var separator: int = text.find("=")
		if separator < 0:
			options[StringName(text)] = "true"
			continue
		options[StringName(text.substr(0, separator))] = text.substr(separator + 1)
	return options


static func int_option(options: Dictionary, key: StringName, fallback: int) -> int:
	if not options.has(key):
		return fallback
	var raw: String = options[key]
	if not raw.is_valid_int():
		return fallback
	return raw.to_int()


static func float_option(options: Dictionary, key: StringName, fallback: float) -> float:
	if not options.has(key):
		return fallback
	var raw: String = options[key]
	if not raw.is_valid_float():
		return fallback
	return raw.to_float()


static func string_option(options: Dictionary, key: StringName, fallback: String) -> String:
	if not options.has(key):
		return fallback
	var raw: String = options[key]
	return raw


static func bool_option(options: Dictionary, key: StringName, fallback: bool) -> bool:
	if not options.has(key):
		return fallback
	var raw: String = options[key]
	return raw == "true" or raw == "1" or raw == "yes"
