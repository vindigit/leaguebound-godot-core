# Independent tests critique

**Local test evidence accepted, with publication still pending.** I reviewed the
roster change against `11c4eaecb19c662fa6e0eff61b2d54dc5c47dda4`, the
focused test sources, actual mutation logs, fixed-fixture audits, the fresh v3
eight-step gate, and its original and archived XML. I did not launch Godot.

The nine construction cases cover the 13,689 ordered base roster pairs,
aligned 468-game marginals, four-game venue/opener crossover, actual rounded
roster identity and capability, eligibility, explicit offsets, direct mirror
preservation, large variation boundaries, and the real home-court diagnostic
consumer. The latter exercises 280 constructed inputs across five competitions,
both modes and orientations, two environments, and seven large-index witnesses.
Three other inline runner consumers have structural source-wiring assertions;
those assertions do **not** demonstrate that their full simulations ran.

`verified_mutations_v2/results.json` records a 9/9 green baseline and nine
source mutants with exit 100, assertion failures, and zero test errors. The
archived adjacent-pair mutant fails the actual crossover test; the int32
narrowing mutant fails at variation 1,073,741,824 in the ninth case. The five
recorded source SHA256 values still match the checkout. Earlier mutants stop
after a failing case, so their short case counts are not 9/9 adverse runs.

The original 22-case FG suite fails exactly the extension, offensive-rebound,
and assist snapshot pins after the roster change. Matched 24-game audit values
exceed the unchanged 0.004 tolerances for those three only. The corrected test
changes their expected values to 0.1192, 0.2429, and 0.6328, respectively;
the turnover and possession pins and every tolerance remain unchanged. Its
22-case rerun passes. These deterministic snapshots are not population effects.

The complete v3 gate ran from `a15bdd00debf2e75925c9376ff316650b46b516b`
with exit 0. All eight steps completed: import, 266-script parse, acceptance,
simulation smoke, 810-build Builder, 80 judged sensitivity metrics, 15 judged
calibration smoke metrics, and GdUnit. Its XML contains 693 actual tests across
55 suites, including the nine construction cases, with zero failed, errored,
skipped, or flaky cases. The retained original XML and archived XML have the
same SHA256, `738a8ae75bc3c15c35113b2a735e2fb78afd303ba6747370404a44235d8806d5`.
The independent gate verifier reconciles unique suite paths and test names to
source, checks all eight step markers and completion records, fails closed on
Git-command errors, and rejects runtime/test edits after gate start. Six
committed golden scenarios and the golden tests are unchanged from `11c4eae`.

These tests support construction and local regression claims. They do not
establish holdout population metrics, an exact-prefix replay, exact published
head CI, or §27.1 certification. Those remain separate acceptance conditions.
