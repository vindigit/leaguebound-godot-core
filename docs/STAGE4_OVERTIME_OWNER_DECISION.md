# Stage 4 owner decision — the §14.2 overtime band

**Status: measurement and decision package. Nothing here is enacted.**
No production value, locked target, tolerance, ruleset version or golden was
changed to produce it.

**2026-09-15 review:** Read [the clock and evidence review](STAGE4_CLOCK_EVIDENCE_REVIEW.md)
before acting on this package. External schedule snapshots now support retaining
4–8% for college and top domestic. The FT path demonstrably charges the shot
clock and player minutes as well as the game clock. Earlier categorical causal
claims below have been narrowed; no owner ruling or production change is enacted.

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

The implementation work has tested whether the specified repertoire suffices. The
missing repertoire was built (§5.25), corrected where it had been gated backwards
(§5.26, §5.27), given ledger continuity and a final-action deadline (§5.29), a
corrected opening-state clock contract (§5.30), a named restart cause and a
single clock policy (§5.31), a re-derived pace environment (§5.32), and a
made-field-goal clock matrix (§5.33).

**The shortfall persists.** §5.28 measured 0.0310 and 0.0223 over 15,000 games
each before most of that work; §5.34 measures 0.0281 and 0.0223 over 4,800 games
each after all of it.

So the question this document puts to the owner is no longer "is the repertoire
missing". It is:

> **Given that the repertoire is present, correctly gated and firing at plausible
> rates, and that the band is still missed by 5.0 and 8.3 standard errors, which
> surface — if any — should move?**

---

## 2. What §5.34 tested

The full tables are in §5.34. These tests narrow the search; they do not prove
that the engine is defect-free or establish causal equivalence between arms.

| Candidate | Verdict | The decisive fact |
| --- | --- | --- |
| A trigger defect | **Not observed in tested coverage** | Regulation ties and overtime entries agree in the reported 12,800 games and fixtures |
| A scorekeeping or horn defect | **No anomaly in those checks; FT clock issue remains** | Award preservation does not prove that timestamp consumption is correct |
| Score granularity | **Not isolated** | Cross-competition transition rates are not an intervention on granularity |
| Late-game decision quality | **Not isolated** | Aggregate action shares do not establish optimal decisions in every relevant state |
| Roster population | **No detectable OT effect of this mirror intervention** | Nonsignificance is not equivalence and does not cover production roster distributions |
| Margin variance | **Width changed; OT effect unresolved** | The mirror intervention narrows SD, but does not establish an OT response or non-response |
| Target validity | **External support for college/NBA proxies** | Independent recount in the linked review; other three competitions not benchmarked |

**Possession availability and tie survival are useful leads, not an exhaustive
causal diagnosis. No new production repair was demonstrated by §5.34.**

---

## 3. Two candidate surfaces: a clock contract and an opening threshold

Both have registered values, but a numeric range does not settle whether event
duration belongs on the game clock. **Neither has been changed.** FT timing is
a contract question; the opening threshold is a separate calibration question.

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

**Why its consumption path needs a contract decision.** In every ruleset this engine
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
shot clock". **The engine does not actually satisfy that second reading:**
`MatchStateReducer._advance_clock` deducts FT timestamp differences from both
clocks and charges player time/fatigue. The replay evidence in the linked review
demonstrates this in all five profiles. **The existing work queue still requires
an owner ruling before changing this consumption path**; this review recommends
a stopped-clock contract rather than silently selecting one.

**Nominal duration accounting, not a causal effect.** From §5.34, per one-possession possession inside
each late window:

| window | free-throw attempts | one-possession possessions | **nominal FT duration, sec/possession** |
| --- | ---: | ---: | ---: |
| college, final 120s | 1,854 | 3,480 | **1.07** |
| college, final 60s | 1,408 | 1,880 | **1.50** |
| college, final 30s | 746 | 963 | **1.55** |
| top domestic, final 60s | 1,255 | 1,878 | **1.34** |
| top domestic, final 30s | 756 | 1,016 | **1.49** |

Across a whole game it is 67.93 seconds at college and 84.85 at top domestic —
2.83% and 2.95% of regulation on that nominal calculation. The one-millisecond
clamp can reduce actual clock consumption. Counting attempts times two is not
an exact sum of charged milliseconds and cannot predict the counterfactual OT rate.

**Expected primary effect.** Preserve time for both teams across FT administration,
regardless of score. More available live time can change subsequent possessions
and decisions. The number and outcomes of those possessions must be measured;
the correction must not selectively return time to a trailing team.

**Expected collateral effects, and they are serious.**

- **Possessions per game may rise across the five competitions.** §14.1 locks those bands
  per competition and §5.32 re-derived `pace_multiplier` against them. Top
  domestic already sits **0.33 from its band ceiling** (§5.33 recorded 102.6700
  against a 103 ceiling), so this change alone could take it out of band.
- Free-throw rate, points per possession and other §14.1 rates may change with
  the altered game sequence and denominator; measure rather than assume direction.
- Review all six golden ledgers for actual changes, and bump the ruleset for a
  production semantic change. Do not predict which fixtures must move.
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
- Review all six golden ledgers for actual changes; a production behaviour
  change requires a ruleset bump.

**Before/after plan.** Matched seeds at 5,000 against a candidate value, all five
competitions, reporting the §5.34 funnel's stages 7 to 10, the
expired-without-attempt rates above, and the §14.1 shooting rows — with college's
field-goal row called out separately because of §5.23.

**Risk.** Medium. It is a smaller, better-bounded change than §3.1, and it is
worth **about a third of college's gap in one arithmetic scenario**: the 54 trailing possessions
per 2,400 games that expire without an attempt inside the final minute would
yield roughly 7 extra level scores at the observed per-possession conversion
rates, against the 21 extra games the range-A floor comparison needs. Those
conversion rates are not validated for the changed states and this is not an upper bound.

---

## 4. What has not been established

Neither surface has a measured counterfactual demonstrating that it closes the
band. The 95.9% relative uplift uses top domestic range A's rounded 2.04%, not
its pooled 2.23%; the baseline must be stated. More possessions and lower tie
survival are associated across competitions, but rules, lineups and state mixes
also differ. No controlled isolation shows possession availability is the sole cause.
The arithmetic scenarios are not upper bounds on nonlinear game outcomes.
Neither surface may change without the existing owner ruling.

---

## 5. The target itself

`BALANCE_SPEC.md` §14.2's "Overtime frequency: 4–8% of games" entered in
`4d98048` — the first commit of this repository — as one universal band for all
five competitions, with **no derivation, no dataset, no seasons, no inclusion
criteria and no overtime definition**. `CalibrationTargets.overtime_frequency()`
cites the specification section that states it, so its provenance is itself.

**Historical access limitation during §5.34, now superseded by the linked review.**
`basketball-reference.com` returned HTTP 403; `fivethirtyeight.com` no longer
resolves. One secondary estimate was reachable and is recorded as **inadmissible**
— it names no data source and states no inclusion criteria, failing the brief's
bar on source, license, definition and transformation record alike.

**The independent recount supports retaining 4–8% for the two benchmarked
competitions:** college conference games 1,155/17,957 (6.43%), NBA regular season
310/6,150 (5.04%). Inclusion limits, season splits, intervals, source hashes and
reproduction are in the review. Different possession economies do not by
themselves invalidate a shared broad band. The other three levels remain unbenchmarked.

---

## 6. Options

### Option A — Rule on the free-throw clock, then re-measure

Resolve the §9.4 ambiguity as a rules question the way §5.33 resolved the
made-field-goal matrix. If the ruling is that the clock stops, change
`free_throw_event_seconds`' consumption path, re-derive pace at all five
competitions, and re-measure.

**Buys:** the Hypothesis E mechanism, at both competitions, and closes a genuine
fidelity gap on its own merits rather than as an overtime fix.
**Costs:** five-competition remeasurement, possible pace re-derivation, ruleset
bump and review of all goldens.
**Closes the band?** Not demonstrated; not the rationale for this correction.

### Option B — Raise `desperation_opening_clock_ms`

**Buys:** more eligible late attempts; OT effect not established by a counterfactual.
**Costs:** interacts with the open college field-goal decision; ruleset bump and
golden review.
**Closes the band?** Unknown.

### Option C — Revisit §5.13's Option 2 for these two competitions

§5.13 recommended competition-specific bands and §5.25 declined in favour of
building the repertoire. The repertoire is now built, and the band is still
missed by 5.0 and 8.3 standard errors on 4,800 games each.

**Not recommended by this review:** different economies do not invalidate a
shared broad target; the independent external recount supports retaining it for
college and top domestic. Changing a band to encompass the simulator would
change a verdict without demonstrating a more faithful model.

### Option D — Accept the gap and stop spending on it

Publish overtime as measured, keep the band judged and failing, and spend the
next increment on the §5.23 college field-goal decision and top domestic's
blowout rate instead.

**Buys:** nothing is changed on incomplete evidence.
**Costs:** a permanent known failure that carries no new information, which is
what §5.13 warned against.

---

## 7. Recommended ruling

**Recommend a stopped-clock FT contract on its own merits, and keep the 4–8%
target for college and top domestic. Do not enact Option C from simulator output.**

The free-throw clock is a fidelity gap whether or not it moves overtime: the
game clock runs during free throws in an engine modelling five rulesets in which
it does not. It should be ruled on for that reason, with pace re-derived exactly
as §5.32 did, and overtime re-measured afterwards as an *outcome* rather than a
target. **It should not be adopted because it might buy overtime** — that is
tuning against a number. §5.34's arithmetic is not a proved bound on its effect.

The repertoire did not suffice to close the gap in the measurements performed.
That does not show the original band is wrong or the remaining engine is correct.

Option B is not recommended on its own: its effect is unresolved and it
interacts with an open owner decision.

The numerical scenarios above and in Options A–C are historical planning
estimates, not proved causal bounds. The repertoire not closing the gap does
not disprove the target. The 2026-09-15 external recount supersedes the earlier
recommendation to reconsider that target without comparable external data.

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
   side in 11 of every 13 games. **No OT effect was detected in the tested mirror
   arm; population effects are not ruled out.** It sits inside the fixture that carries §14.2's
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
