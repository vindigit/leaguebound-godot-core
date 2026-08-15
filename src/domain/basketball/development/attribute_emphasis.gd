class_name AttributeEmphasis
extends RefCounted

## How strongly a build leans on an attribute, for cap generation
## (`BALANCE_SPEC.md` §8.1).
##
## §8.1 assigns cap offsets from the ceiling centre by emphasis: primary build
## attributes receive +4 to +10, secondary strengths +1 to +5, neutral
## attributes -3 to +3, and incompatible physical or specialist tradeoffs -6 to
## -16.
##
## Emphasis is derived from the confirmed build and body, never chosen by the
## player directly and never stored as a gameplay lever. It exists only as an
## input to the one-time cap draw.


enum Value { PRIMARY, SECONDARY, NEUTRAL, INCOMPATIBLE }

const COUNT: int = 4
const IDS: PackedStringArray = ["primary", "secondary", "neutral", "incompatible"]


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown attribute emphasis")
	return StringName(IDS[value])


## Offset bounds for one emphasis level, read from the versioned profile.
## Returns `[minimum, maximum]`.
static func offset_bounds(emphasis: int, profile: ProgressionProfile) -> Array[int]:
	match emphasis:
		Value.PRIMARY:
			return [profile.primary_offset_minimum, profile.primary_offset_maximum]
		Value.SECONDARY:
			return [profile.secondary_offset_minimum, profile.secondary_offset_maximum]
		Value.NEUTRAL:
			return [profile.neutral_offset_minimum, profile.neutral_offset_maximum]
		Value.INCOMPATIBLE:
			return [profile.incompatible_offset_minimum, profile.incompatible_offset_maximum]
		_:
			assert(false, "unknown attribute emphasis")
	return [0, 0]
