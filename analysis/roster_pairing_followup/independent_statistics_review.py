"""Independent complete-phase arithmetic review; never imports analyze.py."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
import audit_phase_archive

OUT = Path(__file__).resolve().parent
TERMS = {
    'possessions_per_game': ('engine_possessions', 'team_games'),
    'points_per_game': ('points', 'team_games'),
    'points_per_possession': ('points', 'engine_possessions'),
    'field_goal_percentage': ('field_goals_made', 'field_goals_attempted'),
    'three_point_percentage': ('three_pointers_made', 'three_pointers_attempted'),
    'free_throw_percentage': ('free_throws_made', 'free_throws_attempted'),
    'three_point_attempt_rate': ('three_pointers_attempted', 'field_goals_attempted'),
    'free_throw_attempt_rate': ('free_throws_attempted', 'field_goals_attempted'),
    'turnovers_per_100_possessions': ('turnovers', 'engine_possessions'),
    'offensive_rebound_percentage': ('offensive_rebounds', 'offensive_rebound_chances'),
    'assist_percentage': ('assists', 'field_goals_made'),
    'home_win_rate': ('home_wins', 'decided_games'),
    'overtime_rate': ('overtime_games', 'games'),
    'close_game_rate': ('close_games', 'games'),
    'blowout_rate': ('blowout_games', 'games'),
    'regulation_possessions': ('regulation_possessions', 'team_games'),
    'overtime_possessions': ('overtime_possessions', 'team_games'),
}
EVENTS = dict(home_win_rate='home_wins', overtime_rate='overtime_games',
              close_game_rate='close_games', blowout_rate='blowout_games')


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def equal(a, b):
    assert np.allclose(a, b, rtol=1e-11, atol=1e-10), (a, b)


def interval(value, influence, record):
    equal(value, record['estimate'])
    centered = influence - influence.mean()
    half = 1.96 * np.sqrt(np.dot(centered, centered) / (117 * 116))
    if half == 0:
        assert record['interval'] is None
    else:
        equal([value - half, value + half], record['interval'])


def ratio(rows, metric):
    num, den = TERMS[metric]
    n = np.array([sum(r[num] for r in rows[i:i+4]) for i in range(0, 468, 4)], float)
    d = np.array([sum(r[den] for r in rows[i:i+4]) for i in range(0, 468, 4)], float)
    value = n.sum() / d.sum()
    scale = 100 if metric == 'turnovers_per_100_possessions' else 1
    return value * scale, (n - value * d) / d.mean() * scale


def vector(row, side):
    return json.dumps(row[side + '_strength']['attribute_vectors'])


def differences(values, record):
    positive, negative = int((values > 0).sum()), int((values < 0).sum())
    assert (record['positive_difference_quartets'], record['negative_difference_quartets'],
            record['equal_count_quartets'], record['sparse_approximation_warning']) == (
                positive, negative, 117 - positive - negative, positive + negative < 10)


def quantiles(samples):
    bounds = np.quantile(samples, [.025, .975])
    return None if bounds[0] == bounds[1] else bounds


def review(phase):
    archive = audit_phase_archive.audit(phase)  # Includes the 20-cell completeness barrier.
    summary_path = OUT / f'{phase}_summary.json'
    summary = read(summary_path)
    count = dict(canonical=0, cell_intervals=0, paired_intervals=0, bootstrap_comparisons=0, venue_intervals=0)
    findings = {}
    for comp, entry in summary['competitions'].items():
        cells, calculated, failures = {}, {}, {}
        for version in ('baseline', 'candidate'):
            for arm in ('home', 'neutral'):
                label = f'{phase}_{version}_{arm}_{comp}'
                rows = read(OUT / 'reports' / f'roster_raw_{label}_{comp}.json')['rows']
                report = read(OUT / 'reports' / f'competition_calibration_{label}.json')
                canonical = {m['metric']: m for m in report['metrics']}
                cells[version, arm] = rows
                for row in rows:
                    assert row['block'] == row['variation'] // 4
                    assert row['opening_home'] == (row['variation'] % 2 == 0)
                    assert row['regulation_possessions'] + row['overtime_possessions'] == row['engine_possessions']
                    assert row['points'] == row['home_score'] + row['away_score']
                    assert row['margin'] == row['home_score'] - row['away_score']
                assert sorted(vector(r, 'home') for r in rows) == sorted(vector(r, 'away') for r in rows)
                if version == 'candidate':
                    for i in range(0, 468, 4):
                        a, b, c, d = rows[i:i+4]
                        assert a['home_strength'] == b['away_strength'] == c['away_strength'] == d['home_strength']
                        assert a['away_strength'] == b['home_strength'] == c['home_strength'] == d['away_strength']
                values = {}
                for metric in TERMS:
                    value, influence = ratio(rows, metric)
                    values[metric] = value, influence
                    recorded = entry['cells'][version + '_' + arm]['metrics'][metric]
                    interval(value, influence, recorded)
                    count['cell_intervals'] += 1
                    if metric not in ('regulation_possessions', 'overtime_possessions'):
                        original = canonical[comp + '.' + metric]
                        equal(value, original['estimate'])
                        assert recorded['canonical_verdict'] == original['verdict']
                        assert recorded['target'] == original.get('target')
                        count['canonical'] += 1
                    if metric in EVENTS:
                        totals = np.array([r[EVENTS[metric]] for r in rows]).reshape(117, 4).sum(1)
                        bearing, complement = int((totals > 0).sum()), int((totals < 4).sum())
                        ec = recorded['event_counts']
                        assert (ec['events'], ec['games'], ec['event_bearing_quartets'], ec['event_free_quartets'],
                                ec['complement_bearing_quartets'], ec['sparse_approximation_warning']) == (
                                    int(totals.sum()), 468, bearing, int((totals == 0).sum()), complement,
                                    bearing < 10 or complement < 10)
                calculated[version, arm] = values
                originals = [m for m in report['metrics'] if m['verdict'] == 'fail']
                assert originals == entry['cells'][version + '_' + arm]['all_canonical_failures']
                failures[version + '_' + arm] = [m['metric'] for m in originals]
        for arm in ('home', 'neutral'):
            before, after = cells['baseline', arm], cells['candidate', arm]
            for side in ('home', 'away'):
                assert sorted(vector(r, side) for r in before) == sorted(vector(r, side) for r in after)
            for metric in TERMS:
                av, ai = calculated['baseline', arm][metric]
                bv, bi = calculated['candidate', arm][metric]
                record = entry['paired_changes'][arm][metric]
                interval(bv - av, bi - ai, record)
                count['paired_intervals'] += 1
                if metric in EVENTS:
                    delta = np.array([b[EVENTS[metric]] - a[EVENTS[metric]] for a, b in zip(before, after)])
                    differences(delta.reshape(117, 4).sum(1), record['paired_event_counts'])
            a = np.array([r['margin'] for r in before]).reshape(117, 4)
            b = np.array([r['margin'] for r in after]).reshape(117, 4)
            rng, sa, sb = np.random.default_rng(22092026), [], []
            for _ in range(10):
                indices = rng.integers(0, 117, size=(1000, 117))
                sa.extend(a[indices].reshape(1000, 468).std(1, ddof=1))
                sb.extend(b[indices].reshape(1000, 468).std(1, ddof=1))
            record = entry['paired_changes'][arm]['final_margin_sd']
            equal([a.std(ddof=1), b.std(ddof=1), b.std(ddof=1)-a.std(ddof=1)],
                  [record['before'], record['after'], record['delta']])
            for values, key in ((sa, 'before_interval'), (sb, 'after_interval'),
                                (np.array(sb)-sa, 'paired_percentile_95_quartet_bootstrap')):
                q = quantiles(values)
                if q is None:
                    assert record[key] is None
                else:
                    equal(q, record[key])
            count['bootstrap_comparisons'] += 1
        venue = {}
        for version in ('baseline', 'candidate'):
            home, neutral = cells[version, 'home'], cells[version, 'neutral']
            assert all(a['home_strength'] == b['home_strength'] and a['away_strength'] == b['away_strength']
                       for a, b in zip(home, neutral))
            hv, hi = calculated[version, 'home']['home_win_rate']
            nv, ni = calculated[version, 'neutral']['home_win_rate']
            margins = np.array([a['margin']-b['margin'] for a, b in zip(home, neutral)]).reshape(117, 4).mean(1)
            record = entry['marginal_venue_contrast'][version]
            interval(hv-nv, hi-ni, record['home_win_difference'])
            interval(margins.mean(), margins-margins.mean(), record['home_minus_neutral_final_margin'])
            delta = np.array([a['home_wins']-b['home_wins'] for a, b in zip(home, neutral)]).reshape(117, 4).sum(1)
            differences(delta, record['home_win_difference']['paired_event_counts'])
            venue[version] = hv-nv, hi-ni, margins
            count['venue_intervals'] += 2
        av, ai, am = venue['baseline']
        bv, bi, bm = venue['candidate']
        record = entry['marginal_venue_contrast']['paired_change']
        interval(bv-av, bi-ai, record['home_win_difference'])
        interval((bm-am).mean(), bm-am-(bm-am).mean(), record['home_minus_neutral_final_margin'])
        bh, bn, ch, cn = [cells[key] for key in (('baseline','home'), ('baseline','neutral'), ('candidate','home'), ('candidate','neutral'))]
        delta = np.array([x['home_wins']-y['home_wins']-z['home_wins']+w['home_wins']
                          for x, y, z, w in zip(ch, cn, bh, bn)]).reshape(117, 4).sum(1)
        differences(delta, record['home_win_difference']['paired_event_counts'])
        count['venue_intervals'] += 2
        findings[comp] = {'canonical_failures': failures}
    return {'phase': phase, 'verdict': 'ACCEPT evidence integrity only', 'checks': count,
            'summary_sha256': hashlib.sha256(summary_path.read_bytes()).hexdigest(),
            'archive_cells_verified': len(archive['cells']), 'competitions': findings,
            'scope': 'Independent arithmetic, no analyzer import; all ten bootstraps recomputed. Fixed-schedule uncertainty, no replication or certification claim.'}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('phase', choices=audit_phase_archive.STARTS)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = review(args.phase)
    with args.output.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(result, stream, indent=2)
        stream.write('\n')
    print(json.dumps(result['checks']))
