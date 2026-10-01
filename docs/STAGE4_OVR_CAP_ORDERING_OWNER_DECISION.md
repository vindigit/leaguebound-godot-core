# Stage 4 exact-cap potential / current ordering decision

Status: **explicit owner decision; no production correction applied**. This is a
deterministic domain and consumer conflict, independent of basketball sampling.
It is not evidence that a generated career currently reaches this example.

BALANCE_SPEC §6.3 requires potential to use the current OVR formula on exact
caps and also requires `CurrentOverall <= MaximumPotentialOverall`. Section
8.3 permits caps below current attributes after specified exceptional changes
and states that a cap reduction alone never lowers current ratings. Those rules
cannot all hold for every permitted domain state.

The reproducible domain example has twenty current attributes and original
caps equal to 80. Two major-injury entries reduce Speed and Stamina caps from
80 to 72, each a permitted eight-point reduction; the current attributes stay
80. Current raw/displayed OVR is 80. The exact-cap potential is
`79.21333333333333`, displayed 79. `CapChangeLedger` retains both injury entries.
The uniform starting vector is an arithmetic counterexample, not a claimed
Builder allocation or observed natural lifecycle state. Reachability and
population prevalence remain untested.

The separate expected-error probe is executable:

```powershell
$godot = 'C:\Users\valexander\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe'
& $godot --headless --path . --script res://tools/ovr_cap_ordering_probe.gd
```

It prints `current=80 exact_cap_potential=79 injury_entries=2`, then actually
enters `DevelopmentProjection._init` and hits its §6.3 ordering assertion.
Godot logs the assertion and returns a partially initialized object with
default current/potential fields 0/0; process exit 0 does not establish success.
The exact log and source hashes are retained in
`analysis/ovr_truthfulness_followup/cap_ordering_owner_evidence.json`.
This deliberate expected error is excluded from the normal runtime gate and
is not counted as a mutation kill. The focused normal suite checks the
calculator/domain facts without intentionally constructing that projection.

An owner must choose which locked guarantee governs these exceptional states.
Each alternative changes a design contract; none is implicitly authorized by
this report:

| Alternative | Consequence |
| --- | --- |
| Keep exact-cap potential; allow current above it after documented cap loss | Preserve §8.3 and the locked formula, revise the universal §6.3 ordering rule and projection-range handling/display interpretation. |
| Keep universal current ≤ potential by preventing caps below current | Revise §8.3's permitted cap-loss behavior and how injury/potential loss is represented. |
| Compute potential from `max(current, exact cap)` | Revise §6.3's exact-cap formula; displayed potential would no longer represent the actual exact-cap vector. |
| Lower current attributes with each cap loss | Revise §8.3's explicit cap-only protection; changes gameplay and injury effects. |

The first option preserves the most arithmetic and cap-loss semantics, but
remains an owner choice. After the decision, add a real generated-development
and injury-path regression, update the approved consumer contracts, and run the
required behavior-change gates if production changes. Do not tune formula
weights or manufacture potential attainment promises to conceal the conflict.
