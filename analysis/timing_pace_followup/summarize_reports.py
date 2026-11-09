"""Compact, unfiltered canonical verdict inventory for the retained diagnostics."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'analysis/timing_pace_followup'
COMPS=['high_school','college','development','overseas','top_domestic_pro']
PHASES=['train_base','train_slow','train_final','validation_a','validation_b']
def source(name):
 for folder in [OUT/'reports', ROOT/'reports']:
  p=folder/name
  if p.exists(): return json.loads(p.read_text(encoding="utf-8-sig"))
 return None
inventory={}
for phase in PHASES:
 rows={}
 for comp in COMPS:
  d=source(f'competition_calibration_{phase}_{comp}.json')
  if d is None: continue
  metrics=d['metrics']; keyed={m['metric']:m for m in metrics}
  rows[comp]={'games':d['context']['sample_count'],'seed_range':d['context']['seed_range'],
   'reported_commit':d['context']['commit_sha'], 'rules_profile':d['context']['rules_profile'],
   'failures':[m for m in metrics if m['verdict']=='fail'],
   'selected':{name:keyed[f'{comp}.{name}'] for name in ['possessions_per_game','points_per_possession','field_goal_percentage','home_win_rate','overtime_rate','close_game_rate','blowout_rate']}}
 inventory[phase]=rows
if len(inventory['train_final'])==5:
 flips={}
 for c in COMPS:
  before=source(f'competition_calibration_train_base_{c}.json')
  after=source(f'competition_calibration_train_final_{c}.json')
  b={m['metric']:m for m in before['metrics']}
  flips[c]=[{'metric':m['metric'],'before':b[m['metric']]['estimate'],'after':m['estimate'],
   'before_verdict':b[m['metric']]['verdict'],'after_verdict':m['verdict']} for m in after['metrics'] if b[m['metric']]['verdict']!=m['verdict']]
 inventory['matched_training_verdict_changes']=flips
venues={}
for c in COMPS:
 d=source(f'home_court_diagnostics_v17_{c}.json')
 if d is None: continue
 venues[c]={'context':d['context'], 'failures':[m for m in d['metrics'] if m['verdict']=='fail'],
  'selected':[m for m in d['metrics'] if any(x in m['metric'] for x in ['attributable_home_win_rate','points_per_100','cap_respected'])]}
inventory['venue']=venues
(OUT/'canonical_verdicts.json').write_text(json.dumps(inventory,indent=2)+'\n')
for phase in PHASES:
 print(phase)
 for c,r in inventory[phase].items():
  s=r['selected'];print(c,'poss',s['possessions_per_game']['estimate'],s['possessions_per_game']['verdict'],'fails',[m['metric'] for m in r['failures']])
print('venue reports',len(venues))
