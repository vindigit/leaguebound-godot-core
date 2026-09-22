"""Render all requested diagnostics, including failed canonical judgments."""
import json
from pathlib import Path

OUT=Path(__file__).resolve().parent
PHASES=['diagnosis','validation_a','validation_b']
COMPS=['high_school','college','development','overseas','top_domestic_pro']
lines=['# Matched roster-pairing measurements','',
       'Each cell has 468 games in 117 quartet clusters. Intervals are exploratory,',
       'conditional on fixed schedule slices; no multiplicity adjustment, equivalence',
       'claim or §27.1 certification. Canonical targets/verdicts are unchanged.',
       'Population home-win verdicts are not controlled even-team venue judgments.','']
summaries={p:json.loads((OUT/f'{p}_summary.json').read_text()) for p in PHASES}
def formatted(value):
    half=value['half_width_95_normal_quartet_cluster']
    note=' ± %.6f'%half if half is not None else ' (interval not estimable)'
    count_info=value.get('paired_event_counts',value.get('event_counts',{}))
    if count_info.get('sparse_approximation_warning'):
        note+='; sparse approximation'
    return '%.6f'%value['estimate']+note
for phase,data in summaries.items():
    lines += [f'## {phase}','']
    for comp in COMPS:
        entry=data['competitions'][comp]
        lines += [f'### {comp}','',
                  '| Home-environment metric | Before | After | Paired change ± 95% half-width | Before → after canonical verdict |',
                  '| --- | ---: | ---: | ---: | --- |']
        for metric,change in entry['paired_changes']['home'].items():
            if metric=='final_margin_sd':
                interval=change['paired_percentile_95_quartet_bootstrap']
                text='not estimable' if interval is None else f'[{interval[0]:+.6f}, {interval[1]:+.6f}]'
                lines.append(f'| Final margin SD | {change["before"]:.6f} | {change["after"]:.6f} | {change["delta"]:+.6f} {text} | diagnostic |')
            else:
                before=entry['cells']['baseline_home']['metrics'][metric]
                after=entry['cells']['candidate_home']['metrics'][metric]
                verdict=f'{before.get("canonical_verdict","diagnostic")} → {after.get("canonical_verdict","diagnostic")}'
                lines.append(f'| {metric} | {change["before"]:.6f} | {change["after"]:.6f} | {formatted(change)} | {verdict} |')
        lines += ['', 'Two-arm venue diagnostics (home minus neutral; no controlled §17.4 verdict):','',
                  '| Metric | Before ± half-width | After ± half-width | Difference ± half-width |',
                  '| --- | ---: | ---: | ---: |']
        for metric in ['home_win_difference','home_minus_neutral_final_margin']:
            vals=[entry['marginal_venue_contrast'][v][metric] for v in ['baseline','candidate','paired_change']]
            text=[formatted(x) for x in vals]
            lines.append('| '+metric+' | '+' | '.join(text)+' |')
        lines += ['', 'All canonical failures, including neutral-arm reports retained for audit:', '']
        for name,cell in entry['cells'].items():
            failures=[f'{m["metric"]}={m["estimate"]:.9f}' for m in cell['all_canonical_failures']]
            lines.append(f'- `{name}`: '+('; '.join(failures) if failures else 'none'))
        lines += ['']
lines += ['## Untouched-range directional checks','',
          'A repeated interval exclusion is an exploratory directional signal on these',
          'two schedule slices, not an adjusted significance claim or certification.','',
          '| Competition | Metric | Validation A change interval | Validation B change interval | Interpretation |',
          '| --- | --- | --- | --- | --- |']
for comp in COMPS:
    a=summaries['validation_a']['competitions'][comp]['paired_changes']['home']
    b=summaries['validation_b']['competitions'][comp]['paired_changes']['home']
    for metric in a:
        if metric=='final_margin_sd':
            ia=a[metric]['paired_percentile_95_quartet_bootstrap'];ib=b[metric]['paired_percentile_95_quartet_bootstrap']
        else:
            ia=a[metric]['interval'];ib=b[metric]['interval']
        sparse=any(x[metric].get('paired_event_counts',{}).get('sparse_approximation_warning',False) for x in [a,b])
        same=ia is not None and ib is not None and not sparse and ((ia[0]>0 and ib[0]>0) or (ia[1]<0 and ib[1]<0))
        verdict='directional signal in both ranges' if same else 'no replicated interval exclusion; unresolved'
        if sparse:
            verdict='sparse discordance; normal approximation unreliable'
        show=lambda interval:'not estimable' if interval is None else f'[{interval[0]:+.6f}, {interval[1]:+.6f}]'
        lines.append(f'| {comp} | {metric} | {show(ia)} | {show(ib)} | {verdict} |')
(OUT/'MEASUREMENTS.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print(OUT/'MEASUREMENTS.md')
