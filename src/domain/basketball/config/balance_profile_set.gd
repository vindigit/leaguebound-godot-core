class_name BalanceProfileSet
extends RefCounted

## The three player-system balance profiles a career is pinned to
## (`GODOT_TDD.md` §5.6, `BALANCE_SPEC.md` §4).
##
## A career stores the version of every profile it was created with and stays
## pinned to them. Bundling the three together makes that pinning a single
## stored fact rather than three that can drift apart, and gives the Gate B0
## configuration-integrity check one place to validate every tunable.


var ratings: RatingsProfile
var builder: BuilderProfile
var progression: ProgressionProfile


func _init(
	p_ratings: RatingsProfile = null,
	p_builder: BuilderProfile = null,
	p_progression: ProgressionProfile = null,
) -> void:
	ratings = p_ratings if p_ratings != null else RatingsProfile.default_profile()
	builder = p_builder if p_builder != null else BuilderProfile.default_profile()
	progression = p_progression if p_progression != null else ProgressionProfile.default_profile()


static func default_set() -> BalanceProfileSet:
	return BalanceProfileSet.new()


## The pinned version triple stored with a career. Any change to this string
## requires a deterministic migration recording old version, new version, and
## reason (`BALANCE_SPEC.md` §4).
func version_signature() -> String:
	return "%s|%s|%s" % [ratings.version, builder.version, progression.version]


func describe_tunables() -> Array[BalanceTunable]:
	var tunables: Array[BalanceTunable] = []
	tunables.append_array(ratings.describe_tunables())
	tunables.append_array(builder.describe_tunables())
	tunables.append_array(progression.describe_tunables())
	return tunables


## Gate B0: every tuneable has a name, unit, safe range, and version, and every
## value sits inside its declared safe range. Returns the failures rather than
## asserting so the configuration-integrity test can report all of them at once.
func validate() -> PackedStringArray:
	var failures: PackedStringArray = []
	var seen: Dictionary = {}
	for tunable in describe_tunables():
		if seen.has(tunable.tunable_name):
			failures.append("duplicate tunable name: %s" % tunable.tunable_name)
		seen[tunable.tunable_name] = true
		if not tunable.is_inside_safe_range():
			failures.append("outside safe range: %s" % tunable.describe())
	if ratings.version.is_empty() or builder.version.is_empty() or progression.version.is_empty():
		failures.append("every profile in the set must carry a version")
	return failures
