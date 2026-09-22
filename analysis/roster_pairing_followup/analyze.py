"""Fixed-schedule, quartet-cluster paired diagnostics; never retunes a target."""
import argparse, json, math
from pathlib import Path
import numpy as np

OUT = Path(__file__).resolve().parent
COMPS = ['high_school', 'college', 'development', 'overseas', 'top_domestic_pro']
TERMS = {
 'possessions_per_game': ('engine_possessions','team_games'),
 'points_per_game': ('points','team_games'),
 'points_per_possession': ('points','engine_possessions'),
 'field_goal_percentage': ('field_goals_made','field_goals_attempted'),
 'three_point_percentage': ('three_pointers_made','three_pointers_attempted'),
 'free_throw_percentage': ('free_throws_made','free_throws_attempted'),
 'three_point_attempt_rate': ('three_pointers_attempted','field_goals_attempted'),
 'free_throw_attempt_rate': ('free_throws_attempted','field_goals_attempted'),
 'turnovers_per_100_possessions': ('turnovers','engine_possessions',100.0),
 'offensive_rebound_percentage': ('offensive_rebounds','offensive_rebound_chances'),
 'assist_percentage': ('assists','field_goals_made'),
 'home_win_rate': ('home_wins','decided_games'),
 'overtime_rate': ('overtime_games','games'),
 'close_game_rate': ('close_games','games'),
 'blowout_rate': ('blowout_games','games'),
 'regulation_possessions': ('regulation_possessions','team_games'),
 'overtime_possessions': ('overtime_possessions','team_games'),
}

def load(phase, version, arm, comp):
    label = f'{phase}_{version}_{arm}_{comp}'
    raw = json.loads((OUT/'reports'/f'roster_raw_{label}_{comp}.json').read_text(encoding='utf-8-sig'))
    report = json.loads((OUT/'reports'/f'competition_calibration_{label}.json').read_text(encoding='utf-8-sig'))
    rows = raw['rows']
    start = {'diagnosis':23400000,'validation_a':28080000,'validation_b':32760000}[phase]
    assert raw['seed_first'] == start+1 and raw['seed_last'] == start+468
    assert raw['competition'] == comp
    assert raw['environment'] == (0.5 if arm=='home' else 0.0)
    assert raw['catalog'] == ('competition-catalog-v3' if version=='baseline' else 'competition-catalog-v4-roster-pairing')
    expected_metrics = set(TERMS)-{'regulation_possessions','overtime_possessions'}
    names = {m['metric'] for m in report['metrics']}
    assert all(f'{comp}.{m}' in names for m in expected_metrics)
    assert all(m == 'sample.meets_certification_size' or m.startswith(comp+'.') for m in names)
    assert len(rows) == 468 and len({r['seed'] for r in rows}) == 468
    assert [r['seed'] for r in rows] == list(range(raw['seed_first'],raw['seed_last']+1))
    assert rows[0]['variation'] % 468 == 0
    for r in rows:
        assert r['games']==1 and r['team_games']==2 and r['decided_games']==1
        assert r['opening_home'] == (r['variation']%2==0)
        assert r['seed'] == r['variation']+1
        assert r['block'] == r['variation']//4
        assert r['regulation_possessions']+r['overtime_possessions'] == r['engine_possessions']
        assert r['home_score']+r['away_score'] == r['points']
        assert r['home_score']-r['away_score'] == r['margin']
    if version=='candidate':
        for i in range(0,len(rows),4):
            a,b,c,d = rows[i:i+4]
            assert a['home_strength']==b['away_strength']==c['away_strength']==d['home_strength']
            assert a['away_strength']==b['home_strength']==c['home_strength']==d['away_strength']
        h = sorted(json.dumps(r['home_strength']['attribute_vectors']) for r in rows)
        a = sorted(json.dumps(r['away_strength']['attribute_vectors']) for r in rows)
        assert h == a
    return rows, report

def ratio(rows, terms):
    num,den,*scales = terms
    scale = scales[0] if scales else 1.0
    n = np.array([r[num] for r in rows], dtype=float).reshape(-1,4).sum(axis=1)
    d = np.array([r[den] for r in rows], dtype=float).reshape(-1,4).sum(axis=1)
    estimate = n.sum()/d.sum()
    influence = (n-estimate*d)/d.mean()
    return float(estimate*scale), influence*scale

def estimate(value, influence):
    half = float(1.96*np.std(influence, ddof=1)/math.sqrt(len(influence)))
    return {'estimate': float(value), 'half_width_95_normal_quartet_cluster': half,
            'interval': [float(value-half),float(value+half)]}

def strength(rows):
    result = {}
    for metric in ['mean_attribute','mean_raw_overall','starter_raw_overall']:
        h = np.array([r['home_strength'][metric] for r in rows])
        a = np.array([r['away_strength'][metric] for r in rows])
        gap = h-a
        result[metric] = {'home_mean': float(h.mean()), 'away_mean': float(a.mean()),
            'home_sd':float(h.std(ddof=1)), 'away_sd':float(a.std(ddof=1)),
            'home_quantiles':np.quantile(h,[0,.05,.25,.5,.75,.95,1]).tolist(),
            'away_quantiles':np.quantile(a,[0,.05,.25,.5,.75,.95,1]).tolist(),
            'gap_mean': float(gap.mean()), 'gap_sd': float(gap.std(ddof=1)),
            'home_stronger': int((gap>1e-9).sum()), 'away_stronger': int((gap< -1e-9).sum()),
            'equal': int((np.abs(gap)<=1e-9).sum()),
            'gap_quantiles': np.quantile(gap,[0,.05,.25,.5,.75,.95,1]).tolist(),
            'gap_values': sorted(set(np.round(gap,9).tolist()))}
    return result

def margin_bootstrap(before, after):
    a = np.array([r['margin'] for r in before], dtype=float).reshape(-1,4)
    b = np.array([r['margin'] for r in after], dtype=float).reshape(-1,4)
    # Same resampled quartets in both arms; fixed diagnostic bootstrap seed.
    rng = np.random.default_rng(22092026)
    indices = rng.integers(0,len(a),size=(10000,len(a)))
    sa = a[indices].reshape(10000,-1).std(axis=1,ddof=1)
    sb = b[indices].reshape(10000,-1).std(axis=1,ddof=1)
    return {'before': float(a.std(ddof=1)), 'after': float(b.std(ddof=1)),
        'delta': float(b.std(ddof=1)-a.std(ddof=1)),
        'paired_percentile_95_quartet_bootstrap': np.quantile(sb-sa,[.025,.975]).tolist(),
        'before_interval': np.quantile(sa,[.025,.975]).tolist(),
        'after_interval': np.quantile(sb,[.025,.975]).tolist(),
        'replicates': 10000, 'seed': 22092026}

def analyze(phase):
    result = {'phase': phase, 'uncertainty_scope': 'Exploratory conditional fixed-schedule quartet clusters; no multiplicity correction or equivalence claim.', 'competitions': {}}
    for comp in COMPS:
        cells = {(v,a): load(phase,v,a,comp) for v in ['baseline','candidate'] for a in ['home','neutral']}
        identities = [[(r['variation'],r['seed']) for r in data[0]] for data in cells.values()]
        assert all(i == identities[0] for i in identities)
        entry = {'cells': {}, 'paired_changes': {}, 'marginal_venue_contrast': {},
                 'home_win_scope': 'Canonical population home-win banding retained verbatim; unequal-team population results are not an even-team environment calibration verdict.'}
        for key,(rows,report) in cells.items():
            name = '_'.join(key)
            metrics = {}
            canonical = {m['metric'].split('.',1)[-1]: m for m in report['metrics']}
            for metric,terms in TERMS.items():
                value,inf = ratio(rows,terms)
                metrics[metric] = estimate(value,inf)
                if metric in canonical:
                    assert abs(value-canonical[metric]['estimate']) < 1e-9, (name,metric)
                    metrics[metric]['canonical_verdict'] = canonical[metric]['verdict']
                    metrics[metric]['target'] = canonical[metric].get('target')
            entry['cells'][name] = {'games':len(rows),'quartets':len(rows)//4,
                'metrics':metrics,'strength':strength(rows),
                'final_margin_mean':float(np.mean([r['margin'] for r in rows])),
                'final_margin_sd':float(np.std([r['margin'] for r in rows],ddof=1)),
                'final_margin_quantiles':np.quantile([r['margin'] for r in rows],[0,.05,.25,.5,.75,.95,1]).tolist(),
                'absolute_final_margin_quantiles':np.quantile([abs(r['margin']) for r in rows],[0,.05,.25,.5,.75,.95,1]).tolist(),
                'all_canonical_failures':[m for m in report['metrics'] if m['verdict']=='fail']}
        for arm in ['home','neutral']:
            a,b = cells['baseline',arm][0],cells['candidate',arm][0]
            for side in ['home_strength','away_strength']:
                assert sorted(json.dumps(r[side]['attribute_vectors']) for r in a) == sorted(json.dumps(r[side]['attribute_vectors']) for r in b), 'Roster marginals changed'
            changes = {}
            for metric,terms in TERMS.items():
                av,ai=ratio(a,terms); bv,bi=ratio(b,terms)
                changes[metric] = {'before':av,'after':bv,**estimate(bv-av,bi-ai)}
            changes['final_margin_sd'] = margin_bootstrap(a,b)
            entry['paired_changes'][arm] = changes
        venue_values = {}
        for version in ['baseline','candidate']:
            h,n = cells[version,'home'][0],cells[version,'neutral'][0]
            assert all(x['home_strength']==y['home_strength'] and x['away_strength']==y['away_strength'] for x,y in zip(h,n))
            hv,hi=ratio(h,TERMS['home_win_rate']); nv,ni=ratio(n,TERMS['home_win_rate'])
            margin_difference = np.array([x['margin']-y['margin'] for x,y in zip(h,n)]).reshape(-1,4).mean(axis=1)
            entry['marginal_venue_contrast'][version] = {
                'home_win_difference':estimate(hv-nv,hi-ni),
                'home_minus_neutral_final_margin':estimate(margin_difference.mean(),margin_difference-margin_difference.mean()),
                'scope':'Two-arm population diagnostic; not the controlled three-arm §17.4 cap verdict.'}
            venue_values[version]=(hv-nv,hi-ni,margin_difference)
        av,ai,am=venue_values['baseline'];bv,bi,bm=venue_values['candidate']
        entry['marginal_venue_contrast']['paired_change'] = {
            'home_win_difference':estimate(bv-av,bi-ai),
            'home_minus_neutral_final_margin':estimate((bm-am).mean(),bm-am-(bm-am).mean())}
        result['competitions'][comp] = entry
    return result

if __name__ == '__main__':
    parser=argparse.ArgumentParser();parser.add_argument('phase');args=parser.parse_args()
    result=analyze(args.phase)
    path=OUT/f'{args.phase}_summary.json'
    path.write_text(json.dumps(result,indent=2)+'\n')
    print(path)
