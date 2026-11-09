# Interval reporting follow-up: execution and limits

This follow-up starts at clean `5196c1ad260a1e648709c98882e7bddd01b70431`.
The baseline's 0/40 proportion report prints [−0.0438108012, 0.0438108012]
instead of Wilson [0, 0.0876216025]. The correction preserves actual endpoints
for aggregation-backed proportions and for margin covariance `_share`, and
prints asymmetric endpoints in `describe()`. The original point estimates,
targets and verdicts are unchanged. Explicit `with_interval` overrides remain
symmetric. Replacing an aggregation that cannot calculate an interval now
clears an old width; in the career mean chains this makes fewer-than-two
observations unavailable instead of retaining a zero-width interval.

`SIMULATION_SPEC.md`, `BALANCE_SPEC.md`, `src/`, calibration targets and
golden files have no diff. These are changes to calibration reporting, not
match-simulation behavior. The historical outputs remain as generated and are
not silently rewritten. The retained baseline defect reproducer remains valid
for those historical reports.

## Commands and results

Executed with Godot `4.7.1.stable.official.a13da4feb` in Windows editor/debug
mode, Node `24.22.1` and Python `3.12.14`. From the repository root:

```powershell
$godot = 'C:\Users\valexander\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
$python = 'C:\Users\valexander\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
& $godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/calibration/test_metric_interval_endpoints.gd -c
& $python analysis/pooled_ratio_followup/verify_moments.py
& $godot --headless --path . --script res://calibration/runners/run_margin_covariance.gd -- --games=2 --competition=high_school --mode=population --label=interval_probe_population
& $godot --headless --path . --script res://calibration/runners/run_margin_covariance.gd -- --games=2 --competition=high_school --mode=mirror --label=interval_probe_mirror
node analysis/pooled_ratio_followup/check_margin_report.cjs reports/margin_covariance_interval_probe_population.json reports/margin_covariance_interval_probe_mirror.json
node analysis/pooled_ratio_followup/run_interval_mutations.cjs $godot
node analysis/pooled_ratio_followup/run_margin_mutation.cjs $godot
node --test tests/tooling/test_interval_replay.cjs
node analysis/pooled_ratio_followup/run_replay_mutations.cjs
$env:GODOT_BIN = '/c/Users/valexander/Downloads/Godot_v4.7.1-stable_win64.exe/Godot_v4.7.1-stable_win64_console.exe'
& 'C:\Program Files\Git\bin\bash.exe' tools/run_checks.sh
```

The focused Godot suite passes 8/8 and the independent Python algebra suite
passes 4/4. The two-game population runner exits 1 because all four judged
shape point estimates miss locked bands in that tiny sample; the mirror
runner exits 0 with four informational shape metrics. The separate Node
checker verifies all eight intervals, half-widths and verdicts from their
actual JSON. Independent review also verified the console lines. This is an
instrument check, not a new calibration baseline or evidence of equivalence.

Seven actual serializer mutants fail their named tests, with the 8/8 focused
suite green before mutation and after each source restoration. One additional
runner source mutant restores the old centered-width behavior and fails a
specific endpoint assertion separately in each runner mode. No crash or
unrelated failure counts as a kill. The runner proof also compares all 151
point-metric signatures per mode across baseline, mutant and clean replay.
There are **eight distinct mutants and nine intended detections**, not nine
mutants. Mutation drivers temporarily rewrite the two named local source
files and restore exact bytes; run them only when another process is not
using those files. The compact JSON proofs retain source/test/driver hashes
and log hashes. Full logs and raw two-game reports remain under ignored
`reports/`.

The five-competition same-prefix comparator has fifteen Node known-answer and
corruption tests, and eleven additional comparator source mutants in isolated
copies; the full fifteen-case suite passes before and after each. Those eleven are
instrument mutants, separate from the eight Godot-source mutants above. The
first attempt at the comparator mutation driver aborted because Node's
`--test-name-pattern` reports one selected test rather than eight; that was a
driver accounting error, not a mutation kill. Its corrected replay and source
hashes are in `replay_mutations.json`. CI now runs both the comparator tests
and the four Python algebra tests. The five-competition replay declares the
same 1–40 seed prefix as the historical 40-per-competition report. Its 98
point-metric records, judgment summary and all competition/role sections
match; fifty Wilson intervals have corrected endpoints, and thirty other
intervals retain their old values. All five declared competitions have 40
games. The comparator checks schema, versioned profiles/RNG, build mode, shard,
sample unit, declared seed range and exact competition identities. Aggregate
equality and declared metadata do not independently prove each game seed or
event ledger. This is a same-prefix reproduction, not an untouched validation
or certification. It exited 1 because the same nine point-verdicts fail; no
target was adjusted.

**Provenance qualification:** this run used a modified working tree at HEAD
`5196c1a`; its report context reads that HEAD and leaves `commit_note` empty
despite the modified serializer. A blank note is not proof of a clean tree.
Separate run-start and gate records retain the actual serializer hash, and
all 287 baseline engine/target/golden fingerprints match. The report header
alone cannot certify the executable source tree. `ReportContext` uses HEAD
and version labels without a working-tree content fingerprint, and the
aggregator identity signature also omits Godot version and dirty note.
Immutable-source verification remains an infrastructure prerequisite.

An additional synthetic probe invokes the real `ReportContext` and
`ReportAggregator` against copied report payloads with declared disjoint
shards. Changing only the declared Godot version leaves their identity
signatures equal and the aggregator accepts them; changing only the dirty note
does the same. Both aggregates remain uncertified because the sample is short.
The probe does not claim a second game sample or demonstrate that any actual
released shards were mixed. Its source, input/source/log hashes and observed
results are retained as `context_identity_probe.gd.txt` and
`context_identity_probe.json`. To reproduce, copy the text file to
`reports/stage4_context_identity_probe.gd` and run
`$godot --headless --path . --script res://reports/stage4_context_identity_probe.gd`.
Adding a note to the signature alone cannot prove source cleanliness when
both notes are blank; any remedy also needs verifiable immutable source
identity and a way to reject unknown or mismatched inputs.

The preliminary full gate was deliberately interrupted during GdUnit when
independent review identified the console, margin-runner and stale-reuse
paths; `preliminary_gate_interruption.json` records its task-owned process,
exit and partial-log hash. It is neither a complete gate nor a failed
basketball verdict. After fixes and mutations, the default eight-step gate
was restarted from the beginning and exited 0: **735/735 cases, 60/60 suites,
280 parsed scripts, zero parse failures, and six unchanged goldens**. The
retained XML, `gate_summary.txt` and `gate_proof.json` record actual counts,
versions and frozen source/log hashes. Builder smoke emits the baseline's
eight ObjectDB and seven resource cleanup diagnostics at exit while its step
passes; the GdUnit zero-error result is not a claim that every log line is
error-free.

## Still open

`docs/STAGE4_POOLED_RATIO_INTERVAL_NOTES.md` explains why pooled FG%/PPP
covariance cannot be reconstructed from current report terms, why finite
precision and missingness need explicit tests, and why preserving team-game
moments would not settle game/quartet dependence. It also cites primary NCAA
and FIBA references relevant to the owner's real-world convention direction;
the competition mapping and release-timing coverage still need implementation
and validation. Statistical
misses, population and deployment coverage, the exact-cap owner decision,
nightly/deep infrastructure proof and §27.1 certification remain open.

## Clean committed-source replay

A second same-prefix replay ran from clean tracked and nonignored HEAD
`f82e69c3b8138e76de26288d46e4bf4083ac1902` with the serializer and runner
hashes recorded in `clean_start.json`. `clean_result.json` records an empty
post-run status and exit 1 for the same nine locked point-verdict failures.
The retained `competition_clean_40_each.json` reports that exact HEAD. The
independent comparator in `clean_comparison.json` again verifies 200 games,
98 unchanged point-metric records, 50 corrected Wilson intervals, 30
preserved other intervals and nine failures. Its metrics and sections also
match the preceding dirty-source replay exactly. Start/end status is external
provenance, not an in-report content attestation; aggregate metadata still
cannot prove individual seeds or event ledgers. This is a reproduction of the
same declared seed prefix, not a new validation range or certification.
