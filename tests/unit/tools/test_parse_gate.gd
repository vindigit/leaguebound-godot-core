class_name TestParseGate
extends GdUnitTestSuite

## The parse/compile gate (`tools/parse_check.gd`, `tools/script_validity.gd`).
##
## The gate this replaces could not fail. It decided whether a script compiled
## with `load(path) == null`, and the GDScript resource loader never returns
## null: it prints its error and hands back the failed script object anyway. The
## measured consequence was a walk over 192 scripts that met a hard syntax
## error, printed "0 failure(s)", and exited 0.
##
## A gate that cannot fail is worse than no gate, because it is read as
## evidence. So the central cases here run **the real gate in a real isolated
## Godot process** and judge its exit status, rather than testing a predicate in
## the abstract. That is the only form of the test that could have caught the
## original defect: every in-process assertion about the predicate would have
## passed just as happily while the shipped gate exited 0.
##
## Running it out of process is also why the malformed fixture is written into
## the source tree rather than to `user://`: the gate walks `res://` roots, and a
## fixture the gate cannot see proves nothing about the gate. The file is created
## inside the test, removed in `after_test` whatever the outcome, and is never
## committed — and one of the cases below proves the tree is clean again by
## running the gate a second time and requiring a pass.

## `calibration` is chosen deliberately. It is the root a gate is most likely to
## lose, because nothing in the pull-request suite executes its runners, and it
## is not walked by GdUnit4's own discovery, so a temporary file there cannot
## disturb the suite that is placing it.
const FIXTURE_PATH: String = "res://calibration/runners/_parse_gate_fixture.gd"

## Preloaded rather than loaded by name so the roots are read with their real
## type. The gate itself is never instantiated here — it extends `SceneTree` and
## would re-enter — only its configuration is inspected.
const ParseCheck := preload("res://tools/parse_check.gd")

const BROKEN_SYNTAX: String = """
extends RefCounted

func broken( -> void:
	pass
"""

const VALID_SOURCE: String = """
extends RefCounted

func value() -> int:
	return 7
"""


## One subprocess run of the gate, shared by the cases that read it. Each launch
## walks the whole tree, so one launch per assertion would dominate the suite.
class GateRun extends RefCounted:
	var exit_code: int
	var output: String

	func _init(p_exit_code: int, p_output: String) -> void:
		exit_code = p_exit_code
		output = p_output


static var _with_fixture: GateRun = null
static var _without_fixture: GateRun = null


func after_test() -> void:
	# Unconditional: a malformed script left behind would break every later run
	# of the gate, which is exactly the failure this suite exists to detect.
	_acquire_fixture_lock()
	_remove_fixture()
	_release_fixture_lock()


func _fixture_lock_path() -> String:
	# GdUnit may execute cases from this suite concurrently. A process-scoped
	# directory gives every case one filesystem-visible critical section without
	# leaving a reusable stale lock after the parent process exits.
	return ProjectSettings.globalize_path(
		"user://leaguebound-parse-gate-%d.lock" % OS.get_process_id())


func _acquire_fixture_lock() -> void:
	var deadline: int = Time.get_ticks_msec() + 30_000
	while DirAccess.make_dir_absolute(_fixture_lock_path()) != OK:
		if Time.get_ticks_msec() >= deadline:
			fail("timed out waiting for the parse-gate fixture lock")
			return
		OS.delay_msec(10)


func _release_fixture_lock() -> void:
	DirAccess.remove_absolute(_fixture_lock_path())


func _remove_fixture() -> void:
	if FileAccess.file_exists(FIXTURE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(FIXTURE_PATH))
	var uid: String = "%s.uid" % FIXTURE_PATH
	if FileAccess.file_exists(uid):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(uid))


func _write_fixture(source: String) -> void:
	var file: FileAccess = FileAccess.open(FIXTURE_PATH, FileAccess.WRITE)
	assert_object(file).is_not_null()
	file.store_string(source)
	file.close()


## Runs the committed gate in its own Godot process and returns its exit status
## and combined output. `OS.get_executable_path()` is the engine currently
## running this suite, so the subprocess is the same build CI would use.
func _run_gate() -> GateRun:
	# The shipped entry point imports before it parses so Godot's virtual
	# filesystem reflects files added or removed since the previous run.
	OS.execute(OS.get_executable_path(), [
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--import",
	], [], true)
	var output: Array = []
	var code: int = OS.execute(OS.get_executable_path(), [
		"--headless",
		"--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tools/parse_check.gd",
	], output, true)
	var lines: PackedStringArray = []
	for line: Variant in output:
		lines.append(str(line))
	return GateRun.new(code, "\n".join(lines))


func _gate_with_fixture() -> GateRun:
	if _with_fixture == null:
		_acquire_fixture_lock()
		_write_fixture(BROKEN_SYNTAX)
		_with_fixture = _run_gate()
		_remove_fixture()
		_release_fixture_lock()
	return _with_fixture


func _gate_without_fixture() -> GateRun:
	if _without_fixture == null:
		_acquire_fixture_lock()
		_remove_fixture()
		_without_fixture = _run_gate()
		_release_fixture_lock()
	return _without_fixture


## The case the whole repair exists for: a malformed script in a walked root
## must make the gate exit nonzero.
func test_a_malformed_script_makes_the_gate_exit_nonzero() -> void:
	var run: GateRun = _gate_with_fixture()

	assert_int(run.exit_code).is_equal(1)
	assert_str(run.output).contains("_parse_gate_fixture.gd")
	assert_str(run.output).contains("did not compile")


## The count printed beside the exit status must agree with it. The defect this
## replaces was precisely a disagreement between the two — "0 failure(s)"
## printed over a hard syntax error — so a gate that exits nonzero while still
## reporting no failures has only moved the lie somewhere else.
func test_the_reported_count_agrees_with_the_exit_status() -> void:
	var run: GateRun = _gate_with_fixture()

	assert_str(run.output).contains("1 failure(s)")


## Removing the fixture must return the repository to a pass, or the gate is
## reporting something other than the state of the tree.
func test_removing_the_fixture_returns_the_gate_to_a_pass() -> void:
	var run: GateRun = _gate_without_fixture()

	assert_int(run.exit_code).is_equal(0)
	assert_str(run.output).contains("0 failure(s)")


## The gate proves on every run that it can still tell a broken script from a
## working one. Without that, a future engine change to the predicate would
## restore the original silent-pass defect with nobody noticing.
func test_the_gate_verifies_its_own_detector_before_walking() -> void:
	var run: GateRun = _gate_without_fixture()

	assert_str(run.output).contains("detector verified")


## A script that compiles must not be reported, or the gate is noise rather than
## evidence.
func test_a_valid_script_is_not_reported() -> void:
	_acquire_fixture_lock()
	_write_fixture(VALID_SOURCE)

	assert_str(ScriptValidity.failure_for(FIXTURE_PATH)).is_empty()
	_remove_fixture()
	_release_fixture_lock()


## Every root the gate is configured to walk must exist and contain scripts. A
## renamed or moved root would otherwise be skipped in silence, which is the
## same false pass arriving by a different route.
func test_every_configured_root_exists_and_contains_scripts() -> void:
	var roots: PackedStringArray = ParseCheck.ROOTS
	assert_int(roots.size()).is_greater(0)
	for root: String in roots:
		assert_bool(DirAccess.dir_exists_absolute(root))\
			.override_failure_message("configured root %s does not exist" % root)\
			.is_true()
		assert_int(_count_scripts(root))\
			.override_failure_message("configured root %s contains no scripts" % root)\
			.is_greater(0)


## `calibration` is named explicitly because nothing in the pull-request suite
## executes its runners, so a type error there survives review and surfaces
## hours into a nightly run.
func test_the_calibration_root_is_covered() -> void:
	assert_array(Array(ParseCheck.ROOTS)).contains(["res://calibration"])


func _count_scripts(path: String) -> int:
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
			found += _count_scripts(full)
		elif entry.ends_with(".gd"):
			found += 1
		entry = directory.get_next()
	directory.list_dir_end()
	return found
