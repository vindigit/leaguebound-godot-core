class_name AttributePointSource
extends RefCounted

## Where an AP-equivalent unit came from, for the source ledger
## (`BALANCE_SPEC.md` §9.7.2).
##
## Every AP-equivalent unit granted or spent records its source, career year,
## executor, and balance-profile version — "for NPCs exactly as for the user".
## The ledger is also how the §9.5 upper guardrail works: exceeding it is not a
## hard cap but triggers a balance warning that the source ledger must explain.
##
## `CREATION` is present so creation AP is *traceable*, not so it is spendable
## as career currency. §7.1 forbids creation AP entering the career wallet in
## any form; `AttributePointLedger` enforces that separately.


enum Value {
	CREATION,        ## §7.1 builder budget; never enters the career wallet
	TRAINING,        ## §9.3 training rewards
	GAME,            ## §9.6 game participation development
	OFFSEASON,       ## §9.5 generic offseason development phase
	NATURAL_GROWTH,  ## §10.2 age-driven natural development
	DECLINE,         ## §10.3 natural decline (recorded as a negative grant)
	AT_CAP_CONVERSION,  ## §9.2 direct progress converted at 50% when at cap
	AUTHORED_EVENT,  ## §8.3 major authored development event
}

const COUNT: int = 8
const IDS: PackedStringArray = [
	"creation",
	"training",
	"game",
	"offseason",
	"natural_growth",
	"decline",
	"at_cap_conversion",
	"authored_event",
]


static func is_valid(value: int) -> bool:
	return value >= 0 and value < COUNT


static func id_of(value: int) -> StringName:
	assert(is_valid(value), "unknown attribute point source")
	return StringName(IDS[value])


static func from_id(id: StringName) -> int:
	for value in range(COUNT):
		if StringName(IDS[value]) == id:
			return value
	assert(false, "unknown attribute point source id")
	return Value.TRAINING
