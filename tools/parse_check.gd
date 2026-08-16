extends SceneTree

## Loads every GDScript in the project so parse and type errors surface as a
## single, complete list.
##
## `--import` builds the global class cache without fully type-checking bodies,
## and the acceptance runner only compiles what it reaches. With
## warnings-as-errors configured in `project.godot`, a file no test happens to
## touch can still be broken. This walks the source tree and loads everything.
##
## Run:
##   godot --headless --path . --script res://tools/parse_check.gd

## `res://calibration` belongs here as much as the rest. Its runners are only
## loaded when someone runs them, so before it was listed a type error in a
## harness that the pull-request gate does not execute would survive review and
## surface hours into a nightly run.
const ROOTS: PackedStringArray = [
	"res://src", "res://tools", "res://tests", "res://calibration",
]

var _checked: int = 0
var _failed: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for root in ROOTS:
		_walk(root)
	print("Parse check: %d script(s) loaded, %d failure(s)" % [_checked, _failed.size()])
	if _failed.is_empty():
		quit(0)
		return
	for path in _failed:
		printerr("FAILED: %s" % path)
	quit(1)


func _walk(path: String) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var full: String = "%s/%s" % [path, entry]
		if directory.current_is_dir():
			_walk(full)
		elif entry.ends_with(".gd"):
			_check(full)
		entry = directory.get_next()
	directory.list_dir_end()


func _check(path: String) -> void:
	_checked += 1
	# `self` scripts extend SceneTree and would re-enter if instantiated, so
	# loading is enough: a parse or type error reports during load.
	var script: Resource = load(path)
	if script == null:
		_failed.append(path)
