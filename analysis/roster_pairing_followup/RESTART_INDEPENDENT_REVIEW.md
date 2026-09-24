# Independent source-scope and restart review

**ACCEPT: bounded source-scope hardening and restart provenance.** This review
does not accept unfinished measurements or substitute for execution evidence.
The baseline is the roster follow-up's
`11c4eaecb19c662fa6e0eff61b2d54dc5c47dda4`, not the earlier timing task's
`15225e8cab5fca2bca9dc2ea4757e2f9e74bbc87`.

## Source-scope verification

Reviewed `verify_change_scope.py` and its `change_scope_review.json`, whose
review head is `a15bdd00debf2e75925c9376ff316650b46b516b`. The verifier checks
the exact permitted calibration and test path sets, unchanged `team_for` and
`balance_profile` code, unchanged standard calibration-runner code, and only
the three previously reviewed fixed-fixture expectation changes in the
existing FG test. It retains code, inline comments, strings, whitespace,
assertions, and tolerances when comparing code; only whole comment and empty
lines are omitted.

An independent Git diff from the follow-up baseline confirmed no changes in
`src`, `.github`, `BALANCE_SPEC.md`, `SIMULATION_SPEC.md`, `project.godot`,
committed golden data, golden scenario construction, or golden tests. This
supports the stated protected-source scope; it is not a claim that every
repository file is unchanged.

The explicit `if not __debug__: raise RuntimeError(...)` guard precedes the
assert-based checks, so optimized Python cannot silently strip the checks and
produce a passing verdict. `resume_cells.py` has the same explicit rejection
in its execution entry point. This review inspected that guard; it did not
launch another game process or independently repeat the parent's `python -O`
rejection invocation.

## Restart inventory and archive checks

The restart enumerates exactly **40** preregistered validation cells: **5 kept**
completed cells and **35 missing** cells to rerun. Completion and missingness,
not metric values or verdicts, determine the queue. Original labels, ranges,
and seeds are reused. `restart_manifest.json` explicitly says it was recorded
after restart launch; it does not falsely claim advance provenance.

The five retained cells are:

- `validation_a_baseline_home_high_school`
- `validation_a_baseline_neutral_high_school`
- `validation_a_baseline_home_college`
- `validation_a_baseline_neutral_college`
- `validation_a_baseline_home_development`

Independently recomputed all **20 SHA256 values** for their process records,
raw reports, canonical reports, and logs. Every value matches the exact hash
in `restart_manifest.json`. Each retained raw report contains **468 rows**,
with variations exactly **28080000 through 28080467** and seeds exactly
**28080001 through 28080468**, in order. Each retained process exit is **1**;
these completed reports are retained without mislabeling their calibration
verdicts as green.

Independently checked both SHA256 and byte length of all **5** archived
interrupted logs under `interrupted_20260922`:

- `validation_a_baseline_home_overseas.txt` — 1352 bytes
- `validation_a_baseline_home_top_domestic_pro.txt` — 1303 bytes
- `validation_a_baseline_neutral_development.txt` — 1261 bytes
- `validation_a_baseline_neutral_overseas.txt` — 1415 bytes
- `validation_a_baseline_neutral_top_domestic_pro.txt` — 871 bytes

All match the manifest. Partial logs are preserved as interruption evidence,
not counted as completed observations. The independently computed runner
hashes also match the manifest:

| Source | SHA256 |
| --- | --- |
| `resume_cells.py` | `8f71d301780c4d8207696bef99eaa10a8200571700821a8ed5174c88f572ae87` |
| `run_cells.py` | `e62660b8be27d23a0e5e4c6676e76f0b2ba77ee15ad3fbba4e59ec6fbd9d345d` |

## Limits of this acceptance

No Godot source was edited, no games were launched, and no outcome analysis
was performed for this review. Completion and acceptance of the fresh full
gate, both holdout ranges, bounded exact-prefix replay, and exact published-head
CI remain pending separate evidence. This review makes no §27.1 certification
claim.
