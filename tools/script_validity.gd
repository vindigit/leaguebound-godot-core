class_name ScriptValidity
extends RefCounted

## Whether a GDScript file actually compiles, and proof that the question can
## still be answered.
##
## ## The defect this replaces
##
## `tools/parse_check.gd` used to decide the question with `load(path) == null`.
## That check can never fire. Measured directly on Godot 4.7.1 against a file
## with a syntax error, a file violating a warning configured as an error, and a
## file with a type error: the resource format loader prints
## `Failed to load script ... with error "Parse error"` and then **returns the
## GDScript object anyway**. `load()` returned non-null in all three cases, so
## the gate walked 192 scripts, met a hard syntax error, and reported
## "0 failure(s)" with an exit status of 0.
##
## The import cache is not the mechanism. `ResourceLoader.load` with
## `CACHE_MODE_IGNORE` returns the same non-null broken object, so re-reading
## from disk changes nothing; the loader simply hands back a resource it has
## already reported as failed.
##
## ## What is used instead
##
## `Script.can_instantiate()` is `false` for a script that did not compile and
## `true` for one that did. Measured across all 192 scripts in `src`, `tools`,
## `tests` and `calibration`, exactly one file reported `false` — the
## deliberately broken one — under each of the three error classes above.
##
## An abstract script is legitimately non-instantiable, so it is exempted. The
## exemption is deliberately narrow: it applies only when the engine reports the
## script abstract **and** the file on disk actually declares `@abstract`. A
## script that failed to compile cannot satisfy the second condition, because
## the annotation is read from the source text rather than from the class the
## engine failed to build.
##
## ## Why the self-test exists
##
## The predicate is an engine behaviour, not a documented contract, and the
## defect it replaces was itself a predicate that silently stopped working. So
## the gate proves on every run that it can still tell a broken script from a
## working one, using two scripts compiled in memory. If that proof fails the
## gate reports failure rather than success, because a detector that cannot
## demonstrate detection is indistinguishable from no gate at all.

## Compiles. Deliberately declares no `class_name`: a global class name already
## registered by the project would make a second compilation of the same source
## fail with "hides a global script class", which is why this self-test uses
## purpose-written sources rather than a file from the tree.
const SELF_TEST_VALID_SOURCE: String = """
extends RefCounted

func value() -> int:
	return 7
"""

## Does not compile. A malformed parameter list is chosen because it fails in
## the parser, the earliest stage, so the self-test does not depend on the
## project's warning configuration being loaded.
const SELF_TEST_BROKEN_SOURCE: String = """
extends RefCounted

func broken( -> void:
	pass
"""

const ABSTRACT_ANNOTATION: String = "@abstract"


## Why `path` is not a usable script, or an empty string when it is fine.
static func failure_for(path: String) -> String:
	var resource: Resource = load(path)
	if resource == null:
		return "load() returned null"
	if not (resource is Script):
		return "loaded as %s rather than a Script" % resource.get_class()

	var script: Script = resource
	if script.can_instantiate():
		return ""
	if script.is_abstract() and _declares_abstract(path):
		return ""
	return "did not compile; see the parse, type, or warning error reported above"


## Whether the detector can still tell a broken script from a working one.
##
## Returns an empty string when it can. Any other value means the gate itself is
## unreliable and the caller must fail rather than pass.
static func self_test() -> String:
	var valid := GDScript.new()
	valid.source_code = SELF_TEST_VALID_SOURCE
	if valid.reload() != OK:
		return "a script that compiles was rejected by the engine"
	if not valid.can_instantiate():
		return "a script that compiles reported can_instantiate() == false"

	var broken := GDScript.new()
	broken.source_code = SELF_TEST_BROKEN_SOURCE
	# The return code is deliberately ignored: what matters is that the
	# predicate the gate actually uses rejects the result, not that this
	# particular engine version happens to report a particular error.
	broken.reload()
	if broken.can_instantiate():
		return "a script that does not compile reported can_instantiate() == true"
	return ""


## Whether the file itself declares an abstract class.
##
## Read from the source text rather than from the compiled class, so a script
## that failed to compile can never be exempted as "abstract".
static func _declares_abstract(path: String) -> bool:
	var source: String = FileAccess.get_file_as_string(path)
	if source.is_empty():
		return false
	for line in source.split("\n", false):
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with(ABSTRACT_ANNOTATION):
			return true
		# Annotations precede the declaration they apply to, so anything past
		# the class header is not one.
		if trimmed.begins_with("func ") or trimmed.begins_with("var "):
			return false
	return false
