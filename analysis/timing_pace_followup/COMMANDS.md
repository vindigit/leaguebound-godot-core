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
failures. Process exit1 with a complete report is therefore expected. Script
errors or absent/incomplete reports invalidate a run.

An initial all-competition invocation omitted `--shards`, triggering the shard
identity assertion. Both processes were interrupted before completing their
first cell, the logs are retained as `aborted_missing_shards_*.txt`, and no
measurements from those processes are included. The corrected runs restart the
same training seeds, which were never designated holdouts.
