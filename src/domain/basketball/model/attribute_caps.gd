class_name AttributeCaps
extends RefCounted

## Exact per-attribute potential caps (`GODOT_TDD.md` §5.5, `BALANCE_SPEC.md` §8).
##
## Caps are a **stored career fact**, not a derived value (`GODOT_TDD.md` §5.7),
## and every cap change is ledgered. Ordinary development never changes a cap
## (§8.3); only the four exceptional events in that table do.
##
## §8.3 carries a rule that is easy to get wrong and is enforced here by
## construction: *a potential-cap reduction by itself never lowers the current
## rating*. A cap may legally fall below the player's current ability. When that
## happens the current rating is untouched and further growth in that attribute
## is blocked until current ability is no longer above the cap. Current-rating
## loss is never inferred from a cap mutation — it requires its own separately
## resolved, visibly explained effect and its own ledger entry.


var _caps: Array[int]


func _init(p_caps: Array[int] = []) -> void:
	_caps = []
	if p_caps.is_empty():
		for _index in range(AttributeKey.COUNT):
			_caps.append(ProgressionProfile.CAP_MAXIMUM)
	else:
		assert(p_caps.size() == AttributeKey.COUNT,
			"exactly one cap per canonical attribute is required")
		for index in range(p_caps.size()):
			var cap: int = p_caps[index]
			assert(
				cap >= ProgressionProfile.CAP_MINIMUM and cap <= ProgressionProfile.CAP_MAXIMUM,
				"cap for %s must lie between %d and %d" % [
					AttributeKey.name_of(index),
					ProgressionProfile.CAP_MINIMUM,
					ProgressionProfile.CAP_MAXIMUM,
				]
			)
			_caps.append(cap)


func cap_for(attribute: int) -> int:
	assert(attribute >= 0 and attribute < AttributeKey.COUNT, "unknown attribute key")
	return _caps[attribute]


func values() -> Array[int]:
	return _caps.duplicate()


## Whether an attribute currently has room to grow. An attribute sitting at or
## above its cap has no room; the "above" case is legal and arises from §8.3
## cap reductions.
func has_room(attribute: int, current_rating: int) -> bool:
	return current_rating < cap_for(attribute)


## Returns a new `AttributeCaps` with one cap replaced. Caps are immutable
## values: an exceptional cap change produces a new instance and a ledger entry
## rather than mutating in place, so a committed cap can never be edited by a
## caller that merely holds a reference to it.
func with_cap(attribute: int, new_cap: int) -> AttributeCaps:
	assert(attribute >= 0 and attribute < AttributeKey.COUNT, "unknown attribute key")
	var updated: Array[int] = _caps.duplicate()
	updated[attribute] = clampi(new_cap, ProgressionProfile.CAP_MINIMUM, ProgressionProfile.CAP_MAXIMUM)
	return AttributeCaps.new(updated)


func duplicate_caps() -> AttributeCaps:
	return AttributeCaps.new(_caps.duplicate())


func signature() -> String:
	var parts: PackedStringArray = []
	for attribute in AttributeKey.all():
		parts.append("%s=%d" % [AttributeKey.name_of(attribute), _caps[attribute]])
	return ";".join(parts)
