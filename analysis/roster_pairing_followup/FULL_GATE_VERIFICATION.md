# Independent local gate verification

**LOCAL GATE ACCEPT.** The completed eight-step run started at
`bf275ccc89e16fe75830fd34a37529faf8df610a` and returned exit 0. This is local
regression evidence only. Final population measurements, bounded prefix replay,
publication, and exact published-head CI require their own completed evidence.
It is not §27.1 certification.

The verifier `verify_full_gate.ps1` independently reads the archived
log, process result, XML, current test sources, Git differences, and original
report 124, then writes its machine-readable verification output to
`full_gate_independent_verification.json`. No Godot process was launched for
this verification.

Reproducing this exact local audit requires the retained, Git-ignored
`reports/report_124/results.xml` for the original-to-archive byte comparison.
A fresh checkout can inspect committed evidence hashes and reconcile counts,
but must also supply that original report to run the script's exact-copy check.

All 55 XML suites reconcile against their source files. Each suite's declared
count equals its actual testcase-node count and source test-function count;
test names match exactly without duplicates. The totals are **692 declared,
692 executed, 692 source functions**, with zero errors, failures, skipped,
flaky, or orphan tests reported. The archived XML is byte-identical to
`reports/report_124/results.xml`.

All eight outer gate steps appear exactly once and the final runner reports
all requested checks passed:

1. Project import completed.
2. Parse checking covered 266 scripts with zero failures.
3. Project-owned headless acceptance passed.
4. Fixed-seed simulation smoke passed its invariants.
5. Builder evaluated 810 builds and passed.
6. Attribute sensitivity judged 80 metrics, with zero failures.
7. Six-game structural calibration smoke judged 15 metrics, with zero failures.
8. GdUnit executed all 692 cases across all 55 suites and returned exit 0.

The golden suite passed committed-hash reproduction, result shape, semantic
scenario coverage, repeat determinism, and serialization checks for all six
committed scenarios. Golden data, scenario construction, and golden tests are
unchanged from the task's starting head `11c4eaecb19c662fa6e0eff61b2d54dc5c47dda4`.
No golden regeneration was used to obtain this result.

At this review, tracked and untracked changes since gate start are restricted
to analysis/evidence, documentation, and UID files. There are no changed Godot
runtime or test-logic files. The machine-readable audit records the exact
review head and changed-path inventory rather than attributing this run to a
future publication head.

The log is not error-free stdout. It includes the deliberate parse-detector
self-test, expected assertion-error test cases, remote port-zero debugger
messages, and Builder shutdown warnings (eight ObjectDB instances and seven
resources still in use). These diagnostics are retained in the archive; the
test-result claim is zero XML/test errors and successful step exits, not the
absence of every `ERROR` string.
