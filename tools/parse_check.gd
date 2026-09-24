extends SceneTree

## Loads every GDScript in the project so parse, type, and warning-as-error
## failures surface as a single, complete list, and exits nonzero when any of
## them does.
##
## `--import` builds the global class cache without fully type-checking bodies,
## and the acceptance runner only compiles what it reaches. With
## warnings-as-errors configured in `project.godot`, a file no test happens to
## touch can still be broken. This walks the source tree and loads everything.
##
## ## This gate previously could not fail
##
## It decided the question with `load(path) == null`, which never happens: the
## GDScript resource loader prints its error and returns the failed script
## object regardless. Measured on Godot 4.7.1, a file with a syntax error was
## walked, reported by the engine as "Failed to load script", and counted as a
## pass — 192 scripts, "0 failure(s)", exit status 0. `ScriptValidity` documents
## the measurement and owns the replacement predicate.
##
## Three things now stand between that defect and a false pass:
##
##   1. The predicate is `Script.can_instantiate()`, which is false exactly when
##      a script did not compile.
##   2. The gate self-tests before it walks anything, so a future engine change
##      that quietly breaks the predicate reports failure instead of success.
##   3. Every configured root must actually contain scripts. A root that has
##      been renamed or moved would otherwise be skipped in silence, which is
##      the same false pass arriving by a different route.
##
## Run:
##   godot --headless --path . --script res://tools/parse_check.gd
##
## Exit status: 0 all scripts compile, 1 at least one did not, 2 the gate could
## not prove it is working. Callers must judge the status, not the printed count.

## Resolved by path rather than by global class name. The global class cache is
## built by an import pass, and a gate that only works after one has run is a
## gate that silently does nothing on a clean checkout — which is the class of
## defect this file exists to remove.
const Validity := preload("res://tools/script_validity.gd")

## `res://calibration` belongs here as much as the rest. Its runners are only
## loaded when someone runs them, so before it was listed a type error in a
## harness that the pull-request gate does not execute would survive review and
## surface hours into a nightly run.
const ROOTS: PackedStringArray = [
	"res://src", "res://tools", "res://tests", "res://calibration",
]

const EXIT_PASS: int = 0
const EXIT_FAILED_SCRIPTS: int = 1
const EXIT_GATE_UNRELIABLE: int = 2

var _checked: int = 0
var _failed: PackedStringArray = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Parse check: self-testing the detector before walking the tree.")
	print("Parse check: the parse error immediately below is deliberate — it is the")
	print("Parse check: broken script the self-test compiles on purpose.")
	var unreliable: String = Validity.self_test()
	if not unreliable.is_empty():
		printerr("Parse check SELF-TEST FAILED: %s" % unreliable)
		printerr("The gate cannot demonstrate that it detects a script which does not "
			+ "compile, so it reports failure rather than an unearned pass.")
		quit(EXIT_GATE_UNRELIABLE)
		return
	print("Parse check: detector verified.")

	# Without the global class cache no script that references a `class_name`
	# can resolve it, and the walk below reports a hundred and fifty failures
	# that are all artefacts of the missing cache. Measured on a checkout with
	# `.godot` removed: the class list is empty and 154 of 193 scripts "fail".
	# That is as useless as the false pass this gate replaced, so it is refused
	# explicitly rather than reported as a result.
	if ProjectSettings.get_global_class_list().is_empty():
		printerr("Parse check CANNOT RUN: the global class cache is empty, so every "
			+ "reference to a class_name would report as a compile failure.")
		printerr("Run `godot --headless --path . --import` first, then re-run this gate.")
		quit(EXIT_GATE_UNRELIABLE)
		return

	for root in ROOTS:
		var found: int = _walk(root)
		if found == 0:
			_failed.append("%s (configured root contains no scripts)" % root)

	print("Parse check: %d script(s) checked, %d failure(s)" % [_checked, _failed.size()])
	if _failed.is_empty():
		quit(EXIT_PASS)
		return
	for entry in _failed:
		printerr("FAILED: %s" % entry)
	quit(EXIT_FAILED_SCRIPTS)


## Walks one root and returns how many scripts it contained.
func _walk(path: String) -> int:
	var found: int = 0
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return 0
	directory.list_dir_begin()
	var entry: String = directory.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = directory.get_next()
			continue
		var full: String = "%s/%s" % [path, entry]
		if directory.current_is_dir():
			found += _walk(full)
		elif entry.ends_with(".gd"):
			found += 1
			_check(full)
		entry = directory.get_next()
	directory.list_dir_end()
	return found


func _check(path: String) -> void:
	_checked += 1
	# These scripts extend `SceneTree` and would re-enter if instantiated, so
	# they are loaded and inspected rather than run.
	var failure: String = Validity.failure_for(path)
	if not failure.is_empty():
		_failed.append("%s: %s" % [path, failure])
