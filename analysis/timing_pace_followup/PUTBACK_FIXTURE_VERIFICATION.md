# Putback fixture verification

Production source: `743d845145268d223736e1bfb3a53bd2bf52fa6b` (Godot `4.7.1.stable.official.a13da4feb`). Production source was unchanged; the verification change is confined to `tests/simulation/test_endgame_corrections.gd`.

`putback_fixture_audit.json` → `old` means **the previously pinned seed 7095 run under the current v17 engine**, not an old-head engine run. Its four putback tags agree with the reconstructed pre-action decisions, and none is eligible for two-for-one. The bounded search starts at 7096, stops at its first qualifying seed 7104, and records every searched ledger. The test now checks every putback tag against the decision active before action load and separately requires one eligible and one tagged two-for-one putback.

Commands from repository root, using the pinned Godot binary:

```powershell
& $GodotBin --headless --path . -s analysis/timing_pace_followup/audit_putback_fixture.gd
& $GodotBin --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -a tests/simulation/test_endgame_corrections.gd
.\analysis\timing_pace_followup\run_putback_wiring_mutation.ps1 -GodotBin $GodotBin
```

`putback_wiring_mutation.json` records the exact test source and production-engine hashes. It runs the corrected test method in isolation, then removes only the putback writer's tag: baseline 1/1 green; mutant killed with 2 assertion failures and 0 errors. The temporary source is restored; shared production files are never mutated. The full focused-suite log is `endgame_corrections_fixture_recheck.log`.

Focused suite result: **19/19 passed, 0 errors, 0 failures**, exit 0 (5min 13s 811ms).

## Fresh-checkout mutation prerequisite

The supplementary mutation runner reuses the isolated copy named in
`analysis/stopped_clock_followup/final_pace_mutations/results.json`. Its archived
machine path is not portable. Before either supplementary mutation on a fresh
checkout, recreate that isolated copy and provenance with:

```powershell
.\tools\run_timing_mutations.ps1 -GodotBin $GodotBin -OutputDirectory analysis/stopped_clock_followup/final_pace_mutations
```

Then run the putback/upset mutation command above. This prerequisite also reruns
the nine timing mutants; it never mutates the shared production checkout.
