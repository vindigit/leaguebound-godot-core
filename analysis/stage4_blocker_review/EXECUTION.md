# Stage 4 Builder/OVR blocker review execution

Starting local HEAD, actual remote branch and PR head were all
`899a3972e48e8ce63de07b47b2e593e9c97df4d2`. The Godot checkout was clean
before authored report files appeared. The expected SHA was checked, not used
to reset another checkout. The unrelated dirty `leaguebound-fresh` archived
React Native checkout and the synced project mirror were left alone.
PR #1 was open, draft and unmerged; exact-head checks `simulation` and
`test-report.xml` succeeded in run 36052758151.

`baseline.json` was captured after report tooling began and discloses those
untracked files. Its 287 production/target/golden fingerprints all match the
starting head. The separate `74b2c550..899a397` diff for those paths is empty.
Archived local gate evidence independently shows 703/703 cases, 57/57 suites,
271 parsed scripts, exit 0; that is previous gate evidence, not a newly run
gate for these authored files.

Both protocols were committed at `51a115e` before confirmatory basketball
outcomes. Production behavior, locked target ranges, tolerances, ratings and
Builder economics are unchanged. Each instrument has its own source freeze
and execution record in the Builder/OVR evidence directories.

## Fresh canonical reproduction

Godot binary:
`C:\Users\valexander\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe`,
version `4.7.1.stable.official.a13da4feb`, Windows editor/debug, asserts active.

```powershell
& $Godot --headless --path . --script res://calibration/runners/run_competition_calibration.gd -- --games=40 --competition=all --label=builder_ovr_current
```

Run on `899a397`, seeds 1–40 per competition, 200 games total; elapsed 425848ms.
Exit **1** is preserved in `competition_exit.txt` because nine locked verdicts
fail. `competition_current_40_each.json` has 98 metrics, 74 judged, 65 pass,
nine fail, 24 informational. All 98 metric rows and all sections are identical
to the previous margin package's 40-per-competition report. Only provenance
and timing differ. All five possession and PPP bands pass. The same existing
seed prefix is intentionally replayed; it is not a new holdout or certification.

## Independent recount and instrument validation

```text
node tools/stage4_blocker_audit.cjs
node tools/render_stage4_blocker_tables.cjs
node --test tests/tooling/test_stage4_blocker_audit.cjs
node tools/run_stage4_blocker_mutations.cjs
```

The audit independently recomputes 92 current aggregation-backed estimates,
98 target/verdict records, all 150 raw ratio estimates from ten corrected
candidate home cells, and controlled venue estimates from 1,000 retained
mirror triples. Every corrected row's declared seed, quartet, ABBA full-roster
identity, opening assignment, score and possession partitions are checked.
The 4,680 corrected games and 3,000 controlled venue games are archived reused
observations, not new simulations. Nineteen failed metric IDs are retained.

The final Node suite passes 13/13. Ten actual-source mutants in an isolated copy
fail the intended named assertions with `ERR_ASSERTION`; syntax/import crashes
are rejected. Clean suites run before and after; instrument bytes are restored
and SHA-256 verified. `mutations_v3/` is the current record, including a
known-answer Wilson-center mutant. `mutations_v2/` retains the accepted
nine-mutant/12-test intermediate version. The seven-mutant/11-test record in
`mutations/` is an initial attempt superseded by the semantic duplicate
mutations. These versions are not added together as independent mutations;
regex-message-only failures are explicitly rejected by the final driver.

The canonical summary's `sample_count=200` means total games, despite its
historical `sample_unit` wording “per competition.” This audit obtains the
actual 40-per-competition count from table rows and metric denominators and
never uses 200 as any single competition's sample. Percentile rows without
stored raw aggregates are retained, not independently reconstructed. The
legacy venue efficiency-gap numerator lacks independent per-arm box aggregates
in that archive; its published failed verdict remains visible.

Independent source inspection also identifies a §27.2 reporting defect:
`calibration/harness/metric_aggregation.gd` calculates a Wilson half-width,
then `calibration/harness/calibration_metric.gd` centers it on the raw estimate.
For 0/40, the published [-0.0438108012, 0.0438108012] differs from Wilson
[0, 0.0876216025]. Historical values are retained, with this warning; the
new analyses do not use those intervals as their uncertainty method.
FG% uses the runner's explicit team-game ratio-width override and is not
classified as a binomial interval. The reporting correction is queued before
§27.2 acceptance and is not a gameplay adjustment.

`final_tooling_tests.json` and `final_tooling_tests.txt` retain 54 passing
analysis cases: 13 blocker Node, 31 OVR Node and 10 Builder Python. Blocker and
Builder executions remain valid against identical sources; the corrected OVR
presentation source was freshly tested at `bdeb425`. JSON separates the exact
executed Windows executable
from the portable `node` / `python3` recipe. Source, test and log hashes are
retained. `production_unchanged.json` verifies all 287 baseline byte hashes,
all three Git trees and an empty production/target/golden/locked-spec diff at
`0a854f8`, plus unchanged Godot/gate sources since `05163e3`.

The complete default eight-step gate passed at the runtime source freeze
`05163e375ccce5d33030a48496424be3581163ef`, from
2026-10-01T03:33:33Z to 04:36:30Z: 727/727 GdUnit cases, 59/59 suites,
279 parsed scripts and zero parse failures. GdUnit reports zero errors,
failures, flaky cases, skips and orphans. All six existing golden assertions
passed against unchanged committed hashes. `full_gate_proof.json`,
`full_gate_gdunit.xml` and `full_gate_summary.txt` retain exact counts,
commands, source/log hashes and diagnostics. The Builder smoke still emits
the baseline's eight ObjectDB / seven resource cleanup diagnostics at exit;
that step passes with process exit 0. The GdUnit zero-error verdict does not
mean every earlier diagnostic line is absent. No Godot source changed after
this complete gate; the later CJS absent-counter presentation correction is
covered by the separate 31-case suite and twelve semantic source mutants.

Final publication uses an ordinary verified fast-forward. Exact final-head
GitHub check runs and PR draft/open/unmerged state are inspected after the
push and recorded in PR #1's description. No nightly/deep infrastructure proof or
full §27.1 certification run is part of this task. The existing fast gate's
100,000 attribute resolutions and six-game structural calibration smoke are
its ordinary approved checks, not full statistical certification.

The preliminary gate begun at `79e7a26` was deliberately interrupted during
GdUnit after review found available career peak/final raw vectors omitted from
the OVR histogram instrument. Its seven earlier steps had completed, but it
is **not a complete eight-step verdict**. The task-owned Godot process was
identified by PID, parent and its exact all-tests command before stopping it;
the launcher exit 127 is an execution interruption, not a failed basketball
contract or a mutation kill. `gate_interruption_v1.json` retains the reason,
source head and partial-log hash. The complete successful gate above restarted
all eight steps after the bounded reporting-field correction froze; the
interrupted attempt is not added to its passing counts.

The independent archive replay executes 152,340 checks with zero failures:
81,533 Builder and 70,807 OVR checks. It uses separate literal arithmetic,
Student-t integration and bootstrap implementations, imports neither report
analyzer, and records the actual source and archive hashes. Those assertions
are audit facts, not extra GdUnit cases or independent basketball samples.
The final semantic mutation counts are fourteen Builder, five OVR GdUnit,
twelve OVR Node and ten blocker Node witnesses (41 total); intermediate
versions are superseded and not summed.
