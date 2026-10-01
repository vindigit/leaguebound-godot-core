extends SceneTree

## Deliberate owner-contract probe, not a gate or normal report. Expected
## assertion: the valid domain-level cap injury below exposes §6.3's ordering
## conflict with §8.3. This uniform example does not establish lifecycle reach.
func _init() -> void:
	var values: Array[int] = []
	for _index in range(20): values.append(80)
	var attributes: PlayerAttributes = PlayerAttributes.from_values(values)
	var caps := AttributeCaps.new(values)
	var ledger := CapChangeLedger.new()
	for key: int in [AttributeKey.Key.SPEED, AttributeKey.Key.STAMINA]:
		caps = caps.with_cap(key, 72)
		ledger.record(10, key, 80, 72, CapChangeLedger.Reason.INJURY, "ovr-owner-conflict-probe")
	var ratings: RatingsProfile = RatingsProfile.default_profile()
	var current: int = OverallCalculator.current_overall(attributes, ratings)
	var maximum: int = OverallCalculator.maximum_potential_overall(caps, ratings)
	print("OWNER_CONTRACT_EXAMPLE current=%d exact_cap_potential=%d injury_entries=%d" % [current, maximum, ledger.entry_count()])
	var attempted := DevelopmentProjection.new(current, maximum, OverallRange.new(maximum, maximum))
	print("OWNER_CONTRACT_PROBE_RETURNED defaults=%d/%d" % [attempted.current_overall, attempted.maximum_potential])
	quit(0)
