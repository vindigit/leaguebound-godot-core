# Reproduction and process record

Use Godot `4.7.1.stable.official.a13da4feb` and Python with NumPy. The baseline
is an isolated detached worktree at `11c4eaecb19c662fa6e0eff61b2d54dc5c47dda4`.
Copy only the new `run_roster_pairing_followup.gd` instrumentation into the
baseline and verify identical runner bytes on both trees. Import each tree
before running scripts. Keep their report directories separate.

The checked-in `run_cells.py` records exact command arguments, elapsed time,
exit code, input-file hashes and raw/report hashes per cell. Its local Windows
Godot and baseline paths are explicit at the top; adjust those installation
paths for another host. It refuses to overwrite a completed cell.

Each competition/arm/source cell runs:

```text
godot --headless --path <tree> --script res://calibration/runners/run_roster_pairing_followup.gd --
  --games=468 --competition=<competition> --shard=<50000|60000|70000>
  --shards=<shard+1> --environment=<0.5|0.0> --label=<unique label>
```

Shard identity selects a declared variation block. These cells do not claim
that all earlier shards were executed. A complete canonical report normally
returns exit 1 because 468 is below §27.1 certification size and additional
metric failures may remain. Missing/incomplete raw data, parse errors or other
exit codes invalidate the cell; a reported metric failure is retained.

The diagnostic baseline starts first. `run_queue.py` waits for all ten baseline
cells and an explicit local structural-review release record, then runs the
frozen candidate diagnostic followed by both untouched ranges on both trees.
All three phases have five competitions and home/neutral arms. Nothing is
selected, refitted or rerun based on the measured verdicts.

```text
python -X utf8 analysis/roster_pairing_followup/run_cells.py --phases diagnosis --versions baseline --workers 5
python -X utf8 analysis/roster_pairing_followup/run_queue.py
python -X utf8 analysis/roster_pairing_followup/analyze.py diagnosis
python -X utf8 analysis/roster_pairing_followup/analyze.py validation_a
python -X utf8 analysis/roster_pairing_followup/analyze.py validation_b
```

The separate four-game instrumentation smoke at variation 40,000,000 is not
part of the experiment. Its tiny-sample metric failures are not interpreted.
The diagnostic and holdout cells use no previously measured seed range from
the timing/pace follow-up.

`candidate_freeze.json` records 514 original tracked production, calibration,
test and contract files on both trees before any candidate outcome. The only
changed original files are the catalog, its three duplicated consumers and
the standard runner's explanatory comment. Test additions and any justified
fixed-fixture expectation corrections are reviewed separately.

## Bounded exact-prefix reproducibility replay

After all 60 experiment cells and CPU-intensive gates have finished, use
`replay_prefixes.py` to replay one aligned quartet for every diagnosis
competition/source/environment combination: 20 cells, 80 games, sequentially.
The tooling is prepared for later execution; its addition does not claim that
any replay has run or passed.

```text
python -X utf8 analysis/roster_pairing_followup/replay_prefixes.py --run-id verification_01
python -X utf8 analysis/roster_pairing_followup/replay_prefixes.py --run-id verification_01 --execute
```

The first command prints the plan only. The second requires every archived
468-game experiment cell to be complete and hash-consistent before launching
anything. Schedule it after the other gates stop; it does not inspect or stop
unrelated processes. Use a new run ID for another attempt: existing replay
archives and generated output labels are never overwritten.

The runner computes `base = shard * games`. The diagnosis base is 23,400,000,
so a four-game replay uses `--games=4 --shard=5850000 --shards=5850001`, yielding
variations 23,400,000–23,400,003 and seeds 23,400,001–23,400,004. Keeping the
original `--shard=50000` with four games would replay the wrong seeds. Original
Godot executable, source-tree paths, competition and environment are read from
each archived process command. Every replay gets a separate `replay_prefix_*`
label; all original experiment files remain untouched.

Under `replay_prefixes/<run-id>/`, each cell records the exact command, complete
runtime GDScript hashes before and after execution, original archive hashes,
expected rows, process log, output documents and hashes, exit/completion state,
and any field-level differences with complete expected/actual rows. Every key
and value in each raw per-game row must match exactly as canonical JSON; no
float tolerance, rounded metric comparison or selective field subset is used.
Metadata, variations and seeds must match too. Object key ordering is ignored;
numeric JSON representations such as `1` and `1.0` remain distinguishable.

Exit 1 from a complete canonical report is retained without interpreting its
metric judgments. Script errors, incomplete output, source drift or any row
mismatch fail the replay tool. The default per-cell timeout is 600 seconds;
on Windows a timed-out replay terminates its own Godot process tree. The final
summary records success only if all 20 cells match. This is a bounded
reproducibility check, not a new measurement range or certification claim.
It covers only the first four diagnosis rows per cell, not holdout replays or
all 468 rows. The replay records the current executable hash and checks its
pinned version; original process records contain no binary digest, so this
does not prove historical binary identity.
