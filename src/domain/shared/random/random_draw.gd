class_name RandomDraw
extends RefCounted

## Deterministic distribution draws layered over the injected `RandomSource`.
##
## `GODOT_TDD.md` §5.2 forbids `randf`, `randi`, `randomize`, and any shared
## global generator in domain code. These helpers therefore consume only the
## injected source, so every draw stays reproducible from the committed seed and
## stream label.
##
## They are free functions rather than methods on `RandomSource` so the
## interface stays minimal: a test double has to implement four primitives, not
## a distribution library.


## Standard normal draw via Box-Muller.
##
## `next_float` may legitimately return exactly 0.0, and `log(0)` is undefined,
## so the first uniform is nudged off zero. The bias this introduces is smaller
## than the float epsilon and cannot move a clipped, rounded rating.
static func standard_normal(source: RandomSource) -> float:
	var uniform_a: float = maxf(source.next_float(), 0.0000000001)
	var uniform_b: float = source.next_float()
	return sqrt(-2.0 * log(uniform_a)) * cos(TAU * uniform_b)


## Normal draw clipped to +/- `clip` standard-deviation-equivalent *units*, as
## `BALANCE_SPEC.md` §8.1 specifies for per-attribute cap noise: "normally
## distributed with standard deviation 2.5 and clipped to +/-6" — the clip is in
## rating points, not sigmas.
static func clipped_normal(
	source: RandomSource,
	mean: float,
	deviation: float,
	clip: float,
) -> float:
	var raw: float = mean + standard_normal(source) * deviation
	return clampf(raw, mean - clip, mean + clip)


## Uniform integer in an inclusive range, delegated to the source so a test
## double controls it directly.
static func integer_in(source: RandomSource, minimum: int, maximum: int) -> int:
	assert(minimum <= maximum, "draw range is inverted")
	return source.range_int(minimum, maximum)


## Uniform float in an inclusive range.
static func float_in(source: RandomSource, minimum: float, maximum: float) -> float:
	assert(minimum <= maximum, "draw range is inverted")
	return minimum + source.next_float() * (maximum - minimum)
