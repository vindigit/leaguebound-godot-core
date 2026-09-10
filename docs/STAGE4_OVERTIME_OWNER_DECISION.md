# Stage 4 owner decision — the §14.2 overtime band

**Status: measurement and decision package. Nothing here is enacted.**
No production value, locked target, tolerance, ruleset version or golden was
changed to produce it.

| | |
| --- | --- |
| Branch / head | `stage4-calibration` |
| Extends | `PROJECT_STATUS.md` §5.34, which measures what this decides on |
| Supersedes | Nothing. §5.13's costed options and §5.25's 2026-09-01 ruling both stand |
| Classification | **Structural** where it describes what the code contains; **measured, not certified** where it reports a number. No figure here reaches the §27.1 sample |
| Decision owner | Project owner. This document does not choose |

---

## 1. The question, stated precisely

The 2026-09-01 owner ruling (`PROJECT_STATUS.md` §5.25) took §5.13's **Option 1**
for college and top domestic: keep the §14.2 4–8% overtime band, and treat the
measured rates as **missing end-of-regulation behaviour** rather than as evidence
the band is unreachable.

That ruling has now been tested to destruction, in the only way it could be. The
missing repertoire was built (§5.25), corrected where it had been gated backwards
(§5.26, §5.27), given ledger continuity and a final-action deadline (§5.29), a
corrected opening-state clock contract (§5.30), a named restart cause and a
single clock policy (§5.31), a re-derived pace environment (§5.32), and a
made-field-goal clock matrix (§5.33).

**Overtime did not move.** §5.28 measured 0.0310 and 0.0223 over 15,000 games
each before most of that work; §5.34 measures 0.0281 and 0.0223 over 4,800 games
each after all of it.

So the question this document puts to the owner is no longer "is the repertoire
missing". It is:

> **Given that the repertoire is present, correctly gated and firing at plausible
> rates, and that the band is still missed by 5.0 and 8.3 standard errors, which
> surface — if any — should move?**

---

## 2. What §5.34 eliminated

Seven of the eight candidate explanations are closed on evidence. The full
tables are in §5.34; this is the summary an owner needs to know the ground is
solid.

| Candidate | Verdict | The decisive fact |
| --- | --- | --- |
| A trigger defect | **Refuted** | Replayed regulation ties and recorded overtime entries agree in **all 12,800 games** of six arms, computed from two different places |
| A scorekeeping or horn defect | **Refuted** | 13 deterministic fixtures, five mutations, all caught. No negative clock, nothing emitted after termination, every awarded free throw taken |
| Score granularity | **Refuted** | Top domestic converts down-two possessions to level **more** often than college (0.3184 against 0.2777) and has the worse overtime rate |
| Late-game decision quality | **Refuted** | Top domestic outperforms college on nearly every per-possession endgame figure and has the worse overtime rate. Shot selection is correct where decisive |
| Roster population | **Refuted, decisively** | Mirrored identical rosters — pregame strength gap exactly zero — move overtime by less than a fifth of its own standard error in both competitions |
| Margin variance | **Confirmed for top domestic only, and not actionable** | Removing an entire population's worth of strength spread narrows the margin SD by 0.87 and 1.23 points and **does not move overtime at all** |
| Target validity | **Not established either way** | §5 below |

**What is left is possession availability and the size of the concentration at
zero, and neither is a defect.**

---

## 3. The two calibration surfaces

Both are registered tunables with documented safe ranges. **Neither has been
changed.** Each is stated here with what it means, why it is the correct surface,
what it would do, what it would break, and how it would be measured.

### 3.1 `free_throw_event_seconds` — the game clock a free throw charges

| | |
| --- | --- |
| Current value | **2** seconds per attempt |
| Safe range | Registered through `describe_tunables()`; Gate B0 owns the bound |
| Written by | `SimulationBalanceProfile` |
| Read by | `ClockResolver.free_throw_ms` → `PossessionEngine._resolve_free_throws` → `_advance_dead_ball` |

**Current semantic meaning.** Each free-throw attempt advances the *event* clock
by two seconds. `_advance_dead_ball` never lets the period expire mid-sequence —
it leaves at least one millisecond, which is the §13.2 correction that stops an
awarded attempt being cancelled by the horn — but the time it consumes **is game
clock**: the reducer's `_advance_clock` folds it into `state.clock_ms` like any
other elapsed time.

**Why it is the correct calibration surface.** In every ruleset this engine
models, the game clock is **stopped** for free throws. The engine charges it.
§5.31 already established the neighbouring half of this rule — that a throw-in
following a whistle costs the offence nothing because the clock was never
running — so the restart after a free throw is correctly free while the free
throws themselves are not.

**What §9.4 actually says**, quoted in full because the ambiguity is the point:

> Dead-ball fouls and free throws use separate event time without incorrectly
> consuming shot-clock time.

That sentence constrains the **shot** clock and is silent on the game clock.
It can be read as "free throws have their own event time, separate from the game
clock" or as "free throws have their own event time, which does not touch the
shot clock". The engine implements the second. **This is the same class of
ambiguity §5.33 required an owner ruling to resolve for the made-field-goal
clock matrix**, and it should be resolved the same way: by a ruling, not by a
developer picking a reading.

**Measured effect, exactly.** From §5.34, per one-possession possession inside
each late window:

| window | free-throw attempts | one-possession possessions | **game clock charged, sec/possession** |
| --- | ---: | ---: | ---: |
| college, final 120s | 1,854 | 3,480 | **1.07** |
| college, final 60s | 1,408 | 1,880 | **1.50** |
| college, final 30s | 746 | 963 | **1.55** |
| top domestic, final 60s | 1,255 | 1,878 | **1.34** |
| top domestic, final 30s | 756 | 1,016 | **1.49** |

Across a whole game it is 67.93 seconds at college and 84.85 at top domestic —
2.83% and 2.95% of regulation. **The per-possession column is exact**: it divides
by the very possessions the attempts were counted in.

**Expected primary effect.** Returning that clock to the trailing team adds
roughly one and a half seconds per late possession, concentrated exactly where
deliberate fouling clusters. It increases the number of possessions a trailing
team gets inside the final minute, which is the Hypothesis E mechanism.

**Expected collateral effects, and they are serious.**

- **Possessions per game rise at all five competitions.** §14.1 locks those bands
  per competition and §5.32 re-derived `pace_multiplier` against them. Top
  domestic already sits **0.33 from its band ceiling** (§5.33 recorded 102.6700
  against a 103 ceiling), so this change alone could take it out of band.
- Free-throw rate, points per possession and every §14.1 rate stated per
  possession move with the denominator.
- All six golden ledgers change, and the ruleset must bump.
- It is a **five-competition** change: high school and overseas are affected
  identically and neither has asked for it.

**Before/after plan.** Matched seeds, identical rosters, one instrument on both
trees, at all five competitions: the §14.1 possessions and points-per-possession
rows first, then §14.2 overtime, close-game and blowout, then the §5.34 funnel.
The §5.32 pace re-derivation is the precedent and the template.

**Risk.** High. It changes the pace environment the whole of §14.1 is calibrated
against, to buy a mechanism worth roughly a tenth of the endgame clock.

### 3.2 `desperation_opening_clock_ms` — when a possession stops running an ordinary opening

| | |
| --- | --- |
| Current value | **5,000** ms |
| Safe range | **0–15,000** ms, registered as `validity.desperation_opening_clock_ms` |
| Written by | `SimulationBalanceProfile` |
| Read by | `PossessionEngine.simulate` → `_open_desperate`; `EndgameStrategy.final_release_due` |

**Current semantic meaning.** Below this much game clock a possession skips the
half-court set: it advances the ball if the clock allows and commits from where
it stands, and `PossessionContext.desperation_opening` makes the selected action
release-due so its duration draw cannot cross the horn unemitted. §5.30 shipped
this and §9.4 states it as a rule.

**Why it is the correct calibration surface.** §9.4 already authorises the
mechanism and leaves the threshold as a bounded tunable — "**below a bounded
game-clock threshold** the offense advances the ball if the clock allows and then
commits to an attempt from wherever it stands". The question is only where the
bound sits, which is exactly what a tunable is for.

**The measured gap.** §5.29 localized the remaining final-possession loss to
possessions opening at five seconds or less and §5.30 closed that band. §5.34
measures the band immediately above it. Possessions opening inside the final ten
seconds, expiring with no attempt at all:

| offence state | college | top domestic |
| --- | ---: | ---: |
| level | 0.4444 | — |
| down 1 | 0.4000 | — |
| down 2 | 0.2326 | — |
| down 3 | 0.3973 | — |

A possession opening between roughly five and thirteen seconds draws an advance
(2–5 s), a half-court entry (2–4 s) and then an action (1–4 s). When the draws
run long it dies in the opening states, before action selection, so
`final_release_due`'s deadline — which protects an action once one has been
*selected* — never reaches it.

**Expected primary effect.** Raising the threshold moves more late possessions
onto the desperation opening, which produces an attempt from wherever the ball
is rather than nothing at all.

**Expected collateral effects.**

- More late attempts from `DEEP` and `BACKCOURT` locations, which §12.6 charges
  for distance — so field-goal percentage falls slightly and three-point rate
  rises slightly, in the last seconds of every period, at every competition.
- **College field-goal percentage is already 21 standard errors below its §14.1
  floor** and is the open §5.22/§5.23 owner decision. Any change that lowers it
  further interacts with that decision and must not be taken independently of it.
- Possessions per game rise slightly (a possession that produces an attempt ends
  differently from one that expires).
- All six golden ledgers change and the ruleset must bump.

**Before/after plan.** Matched seeds at 5,000 against a candidate value, all five
competitions, reporting the §5.34 funnel's stages 7 to 10, the
expired-without-attempt rates above, and the §14.1 shooting rows — with college's
field-goal row called out separately because of §5.23.

**Risk.** Medium. It is a smaller, better-bounded change than §3.1, and it is
worth **at most about a third of college's gap**: the 54 trailing possessions
per 2,400 games that expire without an attempt inside the final minute would
yield roughly 7 extra level scores at the observed per-possession conversion
rates, against the 21 extra games the floor needs.

---

## 4. What neither surface can do

**Neither closes top domestic.** Top domestic needs +95.9% more zero-margin mass.
Its loss is that a level score does not survive: it holds one to the horn 32.9%
of the time against college's 47.6% (z = 2.57, p = 0.010), because §14.1's own
locked possession economy gives every late window a fifth more possessions —
4.77 remaining at the one-minute mark against college's 4.03. **That is a
consequence of the 24-second shot clock and the 96–103 possession band, both
locked by §14.1.** No endgame tunable reaches it.

**Neither is a defect, so neither is authorised without a ruling.** Every
contract in §5.34's audit holds on 12,800 games.

---

## 5. The target itself

`BALANCE_SPEC.md` §14.2's "Overtime frequency: 4–8% of games" entered in
`4d98048` — the first commit of this repository — as one universal band for all
five competitions, with **no derivation, no dataset, no seasons, no inclusion
criteria and no overtime definition**. `CalibrationTargets.overtime_frequency()`
cites the specification section that states it, so its provenance is itself.

**No admissible external evidence could be obtained in this environment.**
`basketball-reference.com` returned HTTP 403; `fivethirtyeight.com` no longer
resolves. One secondary estimate was reachable and is recorded as **inadmissible**
— it names no data source and states no inclusion criteria, failing the brief's
bar on source, license, definition and transformation record alike.

**The target is therefore not established as unsupported**, and this document
does not propose changing it. What can be said is narrower and still useful:
every figure that could be reached at all sits *inside* 4–8%, so the band is not
obviously wrong; and the band is **universal across five competitions whose
possession economies §14.1 deliberately makes different**, which is the same
structural objection §5.13 raised for the blowout band and which §5.34's
possessions-remaining table now measures directly.

---

## 6. Options

### Option A — Rule on the free-throw clock, then re-measure

Resolve the §9.4 ambiguity as a rules question the way §5.33 resolved the
made-field-goal matrix. If the ruling is that the clock stops, change
`free_throw_event_seconds`' consumption path, re-derive pace at all five
competitions, and re-measure.

**Buys:** the Hypothesis E mechanism, at both competitions, and closes a genuine
fidelity gap on its own merits rather than as an overtime fix.
**Costs:** a five-competition pace re-derivation with top domestic 0.33 from its
possessions ceiling; ruleset bump; all six goldens.
**Closes the band?** Almost certainly not on its own.

### Option B — Raise `desperation_opening_clock_ms`

**Buys:** at most about a third of college's gap; nothing decisive for top
domestic.
**Costs:** interacts with the open college field-goal decision; ruleset bump; all
six goldens.
**Closes the band?** No.

### Option C — Revisit §5.13's Option 2 for these two competitions

§5.13 recommended competition-specific bands and §5.25 declined in favour of
building the repertoire. The repertoire is now built, and the band is still
missed by 5.0 and 8.3 standard errors on 4,800 games each.

**Buys:** the specification stops asking five different possession economies for
the same tail — which §5.34's possessions-remaining table now measures rather
than argues.
**Costs:** a locked target moves, and it moves toward a measurement. The defence
is that the 2026-09-01 ruling's own premise has been tested and did not hold.
**Closes the band?** By construction.

### Option D — Accept the gap and stop spending on it

Publish overtime as measured, keep the band judged and failing, and spend the
next increment on the §5.23 college field-goal decision and top domestic's
blowout rate instead.

**Buys:** nothing is changed on incomplete evidence.
**Costs:** a permanent known failure that carries no new information, which is
what §5.13 warned against.

---

## 7. Recommended ruling

**Take Option A on its own merits, not as an overtime fix, and decide Option C
separately.**

The free-throw clock is a fidelity gap whether or not it moves overtime: the
game clock runs during free throws in an engine modelling five rulesets in which
it does not. It should be ruled on for that reason, with pace re-derived exactly
as §5.32 did, and overtime re-measured afterwards as an *outcome* rather than a
target. **It should not be adopted because it might buy overtime** — that is
tuning against a number, and §5.34's arithmetic says it would not be enough
anyway.

Option C is then a separate question with the evidence it needed. The
2026-09-01 ruling was a reasonable bet that the missing repertoire explained the
gap. Four rulesets of corrections later, the repertoire is present, correctly
gated, and firing at plausible rates, and the gap is unchanged. **That premise
has been tested and did not hold**, which is new information the ruling did not
have.

Option B is not recommended on its own: it is worth a third of one competition's
gap and interacts with an open owner decision.

**This recommendation is not enacted.** §14.2 is unchanged, `free_throw_event_seconds`
is unchanged, `desperation_opening_clock_ms` is unchanged, and every measurement
in `PROJECT_STATUS.md` is still judged against the current bands with the
failures recorded as failures.

---

## 8. The exact owner decisions required

1. **Does the game clock stop for free throws?** A §9.4 ruling. If yes, §3.1
   proceeds with a five-competition pace re-derivation and a ruleset bump.
2. **Does `desperation_opening_clock_ms` stay at 5,000?** If it moves, it must be
   decided together with the §5.23 college field-goal package.
3. **Does the 4–8% band stay universal across five competition economies?**
   §5.13's Option 2 with §5.34's evidence, or an explicit decision to keep the
   band and carry the failure.
4. **Does the roster-generation pairing artifact get repaired?** §5.34 §8 records
   that `match_for` pairs home and away so their ladder indices differ by a
   constant eleven steps modulo thirteen, making the population's strength gap a
   two-point distribution rather than a spread, systematically favouring the home
   side in 11 of every 13 games. **It is not an overtime cause** — the mirrored
   arm proves that — but it sits inside the fixture that carries §14.2's
   equal-team home-win target. It belongs to roster-generation calibration.

---

## 9. Reproduction

```
godot --headless --path . --script \
  res://calibration/runners/run_overtime_causal_decomposition.gd -- \
  --games=600 --competition=college --rosters=generated \
  --base=940000 --shard=I --shards=4 --label=college_gen_a --verify-determinism

godot --headless --path . --script \
  res://calibration/runners/run_overtime_causal_decomposition.gd -- \
  --aggregate --label=college_gen_a --shards=4
```

Six arms: `{college, top_domestic_pro}` × `{--base=940000, --base=6940000}`
generated at 4 × 600, plus `--rosters=mirror --base=940000` at 4 × 400 for each
competition. Seed ranges are disjoint from every other section's.

Every arm reports `instrument.repeated_seed_signature_identical` and
`instrument.conditional_outcome_coverage` as judged metrics, and the aggregation
step fails if the canonical and counter-sum recombination paths disagree.
