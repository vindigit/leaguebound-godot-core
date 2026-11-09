# Final construction and mutation review

**FINAL STRUCTURAL AND MUTATION V2 ACCEPT.** This review concerns the corrected
diagnostic consumer and focused construction tests. The earlier 692-case gate
is historical; acceptance of the new 693-case complete gate, population
measurements, replay, and published-head CI remains separate.

The ninth case invokes the actual `_venue_input` implementation through a
subclass overriding `_run` with a no-op. This prevents the inherited deferred
CLI runner from launching simulations. The instance is freed on the normal
path and the roster-mismatch failure path; both baseline and adverse runs
report zero orphans.

The test covers five competitions, mirror and population modes, both venue
orientations, and environments 0 and 0.5. Its seven variation witnesses include
1073741823, 1073741824, 1073741825, 2147483648, 2^40, 2^56, and 2^56+1.
Expected mirror inputs retain int64 arithmetic without packing into int32.
The upper witness remains safe through the roster's multiplication by 37.
Comparisons retain roster ratings, bodies, roles, tendencies, rotation and
game plans, identities, availability, environment, opener, and profile versions.
These are fixture-construction checks, not game-outcome claims.

The archived exact old consumer fails only the new ninth case at variation
1073741824, high-school mirror, forward venue, environment 0: nine cases
executed, one assertion failure, zero errors/orphans, exit 100. Its first eight
cases remain green. The corrected consumer passes all nine cases with exit 0
and zero failures/errors/skips/flaky/orphans.

The completed `verified_mutations_v2` harness kills all nine actual-source
mutants by assertions with exit 100 and zero errors. No log contains a parser
or script error. Earlier mutants may stop after the first failing test; this
does not imply all nine cases executed under every mutant. The new int64
narrowing mutant executes nine cases and fails only the new boundary case at
the same 1073741824 witness.

Independent checks compared every recorded summary and exit to its actual
log, verified the old-consumer log hash, and compared all five recorded source
SHA256 values against both current shared files and the retained restored
isolated copy. All matched exactly, including BOM bytes. Restoration uses
`ReadAllBytes`/`WriteAllBytes`. The machine-readable inventory is
`independent_v2_review.json`.

The consumer correction preserves scalar int64 mirror indices and confines
the packed helper values to population mode. Catalog pairing, engine formulas,
probabilities, pace values, targets, and tolerances are unchanged by this fix.
