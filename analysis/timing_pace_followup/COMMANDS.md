# Commands and process outcomes

All invocations use Godot `4.7.1.stable.official.a13da4feb`, `--headless --path .`.
The Windows console executable is used locally. Run from the repository root.

Training runs (each competition separately; ids high_school, college,
development, overseas, top_domestic_pro):

```text
--script res://calibration/runners/run_timing_pace_followup.gd --
--games=200 --competition=<id> --shard=85000 --shards=85001
--pace-scale=1.0 --label=train_base_<id>
```

Repeat at `--pace-scale=1.1 --label=train_slow_<id>` on identical variations.
The large shard index selects the declared seed block; these diagnostic cells
are not a claim that a complete 85001-shard report was executed or aggregated.
Each canonical report deliberately fails `sample.meets_certification_size` at
this diagnostic sample, in addition to its independently reported metric
failures. Process exit 1 with a complete report is therefore expected. Script
errors or absent/incomplete reports invalidate a run.

An initial all-competition invocation omitted `--shards`, triggering the shard
identity assertion. Both processes were interrupted before completing their
first cell, the logs are retained as `aborted_missing_shards_*.txt`, and no
measurements from those processes are included. The corrected runs restart the
same training seeds, which were never designated holdouts.

Validation uses the same runner, scale 1.0, games 400, per competition:
`--shard=45000 --shards=45001 --label=validation_a_<id>` and
`--shard=47500 --shards=47501 --label=validation_b_<id>`.
The frozen source and timestamp are recorded before launch in
`validation_freeze.json`. Complete canonical reports still return exit 1 for
short certification samples and any recorded unrelated failures.

Home-court recheck uses the canonical runner:

```text
--script res://calibration/runners/run_home_court_diagnostics.gd --
--games=200 --competition=<id> --range=diagnosis --mode=mirror
--environment=0.5 --emit-pairs=true --label=v17_<id>
```

This is 200 matched fixtures/profile, each with home, neutral and reversed arms,
so 1000 fixtures/3000 simulations across all five. It is a diagnostic recheck on
the established diagnosis block, not a fresh pace holdout. Complete run exit
codes are retained per profile; a failed venue band is not relabeled as a pass.

The full local eight-step gate is a single `tools/run_checks.sh` invocation,
using Git Bash and the pinned Windows console binary through `GODOT_BIN`.
`full_gate.txt` and `full_gate_result.json` retain its outcome. Mutation recheck
under the fitted vector is archived in
`analysis/stopped_clock_followup/final_pace_mutations/`.

Final training recheck repeats the 200-game training command at scale 1.0 after
applying the fitted vector, with `--label=train_final_<id>`. The canonical HEAD
field is `76ce60c` because the processes started before the candidate commit;
profile bytes match `743d845` and `candidate-profile-hash.json`. Base/slow canonical
HEAD `15225e8` likewise names the checkout before its already-applied timing patch,
not an old-head simulation. Frozen source hashes are the code provenance.

The first full-gate attempt found a stale fixed-seed endgame putback test. It
was stopped after that assertion failure; `first_gate_attempt.txt`, its process
result and `first_gate_attempt_disposition.json` retain the failure and explicit
incomplete disposition. It is not counted as a passing or completed gate.

The independently reviewed test-only correction is commit `401be24`; all 19
focused cases pass and removing only the production putback tag is rejected by
two assertions in an isolated copy. See `PUTBACK_FIXTURE_VERIFICATION.md`.
The second full-gate invocation restarts all eight steps at that commit. Its
`src`, `calibration` and project settings are identical to frozen `743d845`.
Venue cells that start after this test-only commit may report `401be24` instead
of `743d845`; this does not change their simulation inputs or thaw the pace fit.


The second attempt completed with exit 100 on the score-margin upset-count
guard. It ran 670 cases; 13 later cases in that suite were not run after the
failure, despite the XML root declaring 683. Retain `second_gate_attempt.txt`,
`second_gate_attempt_result.json` and `second_gate_attempt_results.xml`.
A retrospective review records that the same failure had also been present in
the stopped first attempt and was missed before that restart.

The reviewed test-contract correction is `54fdffd`: original 24-game seeds,
sample and remaining distribution bounds are unchanged, the original 0/24
upset result is archived, and a selected full-game witness replaces its
unsupported finite-sample reachability assertion. The focused suite passes
19/19 and a valid-ledger forced-favorite mutant is assertion-killed. See
`SCORE_MARGIN_REACHABILITY_VERIFICATION.md` for commands and all limits.
The final invocation restarts all eight steps at `54fdffd`. Production and
calibration inputs still match frozen `743d845`; no holdout is refitted.

The final invocation completed with exit 0: all eight steps passed, including
684 actual and declared test cases in 54 suites, with zero errors, failures,
skips, flaky tests or orphans. Both independent critics accepted the complete
local evidence. See full_gate_result.json, full_gate_audit.json and
full_gate_results.xml. Published-head CI is separately verified on PR #1.
