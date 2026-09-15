import csv
import tempfile
import unittest
from pathlib import Path

from recount import classify, inspect_file, integer, proportion


def row(**changes):
    result = dict(game_id='1', season='2025', status_type_completed='true',
                  type_abbreviation='STD', season_type='2', format_regulation_periods='4',
                  status_period='4', home_score='100', away_score='90',
                  conference_competition='false', date='2025-01-01T00:00Z')
    result.update(changes)
    return result


class RecountTests(unittest.TestCase):
    def test_regular_game(self):
        self.assertEqual(classify(row(), 'nba'), (None, 2, False, False))

    def test_multiple_overtimes_counts_one_game(self):
        self.assertTrue(classify(row(status_period='6'), 'nba')[2])

    def test_college_two_periods(self):
        self.assertTrue(classify(row(format_regulation_periods='2', status_period='3'), 'mbb')[2])

    def test_special_nba_events_excluded(self):
        for code in ['ALLSTAR', 'CC']:
            self.assertEqual(classify(row(type_abbreviation=code), 'nba')[0], 'all_star_or_cup_final')

    def test_college_conference_final_not_nba_cup(self):
        self.assertIsNone(classify(row(type_abbreviation='CC', format_regulation_periods='2', status_period='2'), 'mbb')[0])

    def test_playin_separate(self):
        self.assertEqual(classify(row(season_type='5'), 'nba')[1], 5)

    def test_incomplete_excluded(self):
        self.assertEqual(classify(row(status_type_completed='False'), 'nba')[0], 'not_completed')

    def test_forfeit_not_full_game(self):
        self.assertEqual(classify(row(status_period='0'), 'nba')[0], 'not_full_game_or_forfeit')

    def test_final_tie_rejected(self):
        self.assertEqual(classify(row(away_score='100'), 'nba')[0], 'invalid_final_score')

    def test_nonstandard_regulation_rejected(self):
        self.assertEqual(classify(row(format_regulation_periods='1'), 'nba')[0], 'nonstandard_regulation')

    def test_linescore_catches_false_overtime(self):
        r = row(format_regulation_periods='2', status_period='3',
                home_linescores="[{'value': 40} {'value': 50} {'value': 10}]",
                away_linescores="[{'value': 40} {'value': 40} {'value': 10}]")
        self.assertEqual(classify(r, 'mbb')[0], 'regulation_tie_disagrees_with_period')

    def test_valid_overtime_linescores(self):
        r = row(format_regulation_periods='2', status_period='3',
                home_linescores="[{'value': 40} {'value': 40} {'value': 20}]",
                away_linescores="[{'value': 40} {'value': 40} {'value': 10}]")
        self.assertEqual(classify(r, 'mbb'), (None, 2, True, True))

    def test_bad_total_rejected(self):
        r = row(home_linescores="[{'value': 2}]", away_linescores="[{'value': 3}]")
        self.assertEqual(classify(r, 'nba')[0], 'line_score_totals_or_period_count_disagree')

    def test_wilson_independent_known_counts(self):
        result = proportion(50, 1000)
        self.assertAlmostEqual(result['wilson_95'][0], .03813026, places=7)
        self.assertAlmostEqual(result['wilson_95'][1], .06531382, places=7)
        self.assertEqual(result['rate'], .05)

    def test_empty_is_not_zero(self):
        with self.assertRaises(ValueError):
            proportion(0, 0)

    def test_numeric_validation(self):
        for value in ['nan', 'inf', '2.5']:
            with self.assertRaises(ValueError):
                integer(value)

    def test_truncated_season_rejected_whole(self):
        with tempfile.TemporaryDirectory() as temp:
            p = Path(temp)/'bad.csv'
            p.write_text('game_id,season,status_type_completed\n1,2025\n')
            q, records = inspect_file(p, 'mbb', 2025)
            self.assertEqual(q['rejected_season'], 'malformed_or_truncated_csv')
            self.assertEqual(records, [])

    def test_conflicting_duplicates_fail_closed(self):
        with tempfile.TemporaryDirectory() as temp:
            p = Path(temp)/'bad.csv'
            first = row(format_regulation_periods='2', status_period='2')
            with p.open('w', newline='') as f:
                writer = csv.DictWriter(f, fieldnames=first)
                writer.writeheader()
                writer.writerows([first, dict(first, home_score='101')])
            q, records = inspect_file(p, 'mbb', 2025)
            self.assertEqual(q['rejected_season'], 'conflicting_duplicate_id')
            self.assertEqual(records, [])


if __name__ == '__main__':
    unittest.main()
