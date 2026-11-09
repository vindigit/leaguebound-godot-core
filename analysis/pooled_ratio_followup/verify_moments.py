"""Independent known answers for pooled ratio moments; standard library only.

This verifies algebra, not whether team-games are independent observations.
Run: python analysis/pooled_ratio_followup/verify_moments.py
"""
import math
import unittest


def moments(pairs):
    return (len(pairs), sum(y for y, x in pairs), sum(x for y, x in pairs),
            sum(y*y for y, x in pairs), sum(x*x for y, x in pairs),
            sum(y*x for y, x in pairs))


def combine(*shards):
    return tuple(sum(column) for column in zip(*shards))


def half_width_from_moments(m):
    n, sy, sx, syy, sxx, syx = m
    if n < 2 or sx <= 0:
        return None
    ratio = sy / sx
    residual_sq = syy - 2 * ratio * syx + ratio * ratio * sxx
    return 1.96 * math.sqrt(max(0.0, residual_sq) / (n - 1) / n) / (sx / n)


def half_width_from_vectors(pairs):
    n = len(pairs)
    sx = sum(x for y, x in pairs)
    if n < 2 or sx <= 0:
        return None
    ratio = sum(y for y, x in pairs) / sx
    residual_sq = sum((y - ratio*x)**2 for y, x in pairs)
    return 1.96 * math.sqrt(residual_sq / (n - 1) / n) / (sx / n)


class PooledRatioTests(unittest.TestCase):
    def test_unequal_shards_reconstruct_concatenated_covariance(self):
        left = [(2, 10), (7, 14)]
        right = [(4, 30), (12, 20), (1, 5), (8, 11)]
        pooled = combine(moments(left), moments(right), moments([]))
        self.assertEqual(pooled, moments(left + right))
        self.assertAlmostEqual(half_width_from_moments(pooled),
                               half_width_from_vectors(left + right), places=13)
        shard_mean = (half_width_from_vectors(left) + half_width_from_vectors(right)) / 2
        self.assertNotAlmostEqual(shard_mean, half_width_from_moments(pooled), places=4)

    def test_pairing_changes_uncertainty_even_with_identical_totals(self):
        teams = [(2, 10), (1, 10), (9, 10), (8, 10), (5, 10), (5, 10)]
        games = [(teams[i][0] + teams[i+1][0], teams[i][1] + teams[i+1][1])
                 for i in range(0, len(teams), 2)]
        self.assertEqual(sum(y for y, x in teams), sum(y for y, x in games))
        self.assertEqual(sum(x for y, x in teams), sum(x for y, x in games))
        self.assertNotAlmostEqual(half_width_from_vectors(teams),
                                  half_width_from_vectors(games), places=4)
        self.assertAlmostEqual(half_width_from_moments(moments(games)),
                               half_width_from_vectors(games), places=13)

    def test_insufficient_and_zero_opportunity_are_unavailable(self):
        for sample in ([], [(0, 0)], [(0, 0), (0, 0)]):
            self.assertIsNone(half_width_from_moments(moments(sample)))

    def test_constant_ratio_exposes_floating_point_cancellation(self):
        sample = [(0, 0), (1, 10), (9, 90)]
        self.assertEqual(half_width_from_vectors(sample), 0.0)
        self.assertLess(half_width_from_moments(moments(sample)), 1e-7)


if __name__ == '__main__':
    unittest.main(verbosity=2)
