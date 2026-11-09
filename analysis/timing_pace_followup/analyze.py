"""Recompute diagnostic game-cluster estimates and matched effects from raw terms."""
import json, math, statistics, sys
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'analysis/timing_pace_followup'
COMPS = ['high_school', 'college', 'development', 'overseas', 'top_domestic_pro']
BANDS = {'high_school': [61,72], 'college':[64,73], 'development':[88,101], 'overseas':[70,82], 'top_domestic_pro':[96,103]}
METRICS = {
 'possessions':('engine_possessions','team_games'), 'points_per_game':('points','team_games'),
 'ppp':('points','engine_possessions'), 'fg':('field_goals_made','field_goals_attempted'),
 'three':('three_pointers_made','three_pointers_attempted'), 'ft':('free_throws_made','free_throws_attempted'),
 'three_attempt_rate':('three_pointers_attempted','field_goals_attempted'),
 'fta_rate':('free_throws_attempted','field_goals_attempted'), 'turnover_rate':('turnovers','engine_possessions'),
 'orb':('offensive_rebounds','offensive_rebound_chances'), 'assist':('assists','field_goals_made'),
 'home_win':('home_wins','decided_games'), 'overtime':('overtime_games','games'),
 'close':('close_games','games'), 'blowout':('blowout_games','games'),
 'regulation_possessions':('regulation_possessions','team_games'), 'overtime_possessions':('overtime_possessions','team_games'),
}
def load(label, comp):
 name = f'pace_raw_{label}_{comp}_{comp}.json'
 path = OUT / 'reports' / name
 if not path.exists():
  path = ROOT / 'reports' / name
 data=json.loads(path.read_text(encoding="utf-8-sig")); rows=data['rows']
 assert len({r['seed'] for r in rows})==len(rows)
 assert [r['seed'] for r in rows]==list(range(data['seed_first'],data['seed_last']+1))
 for r in rows:
  assert r['regulation_possessions']+r['overtime_possessions']==r['engine_possessions']
 return data

def ratio(rows, terms):
 num, den=terms; n=len(rows)
 d=sum(r[den] for r in rows); value=sum(r[num] for r in rows)/d
 inf=[(r[num]-value*r[den])/(d/n) for r in rows]
 half=1.96*statistics.stdev(inf)/math.sqrt(n) if n>1 else None
 return {'estimate':value, 'half_width_95_normal_game_cluster':half},inf

def summarize(label):
 result={}
 for c in COMPS:
  data=load(label,c)
  result[c]={'pace':data['pace_multiplier'],'seed_first':data['seed_first'],'seed_last':data['seed_last'],
   'games':len(data['rows']), 'metrics':{m:ratio(data['rows'],terms)[0] for m,terms in METRICS.items()}}
  value=result[c]['metrics']['possessions']['estimate']; lo,hi=BANDS[c]
  result[c]['possession_band']=BANDS[c]; result[c]['possession_pass']=lo<=value<=hi
 return result

def paired(before, after):
 result={}
 for c in COMPS:
  a,b=load(before,c),load(after,c)
  assert [(r['variation'],r['seed']) for r in a['rows']]==[(r['variation'],r['seed']) for r in b['rows']]
  result[c]={}
  for m,t in METRICS.items():
   av,ai=ratio(a['rows'],t);bv,bi=ratio(b['rows'],t)
   delta=bv['estimate']-av['estimate']; se=statistics.stdev([y-x for x,y in zip(ai,bi)])/math.sqrt(len(ai))
   result[c][m]={'before':av['estimate'],'after':bv['estimate'],'delta':delta,'paired_half_width_95_normal_game_cluster':1.96*se}
 return result

def fit():
 a,b=summarize('train_base'),summarize('train_slow');result={}
 for c in COMPS:
  n0=a[c]['metrics']['possessions']['estimate'];n1=b[c]['metrics']['possessions']['estimate']
  p0=a[c]['pace'];p1=b[c]['pace']; target=statistics.mean(BANDS[c])
  assert n1<n0
  slope=(1/n1-1/n0)/(p1-p0)
  pstar=p0+(1/target-1/n0)/slope
  result[c]={'n0':n0,'n1':n1,'p0':p0,'p1':p1,'interior_objective':target,'inverse_slope':slope,'unrounded_fit':pstar,'pace':round(pstar,3)}
 ordered=['high_school','top_domestic_pro','development','overseas','college']
 assert all(result[a]['pace']<result[b]['pace'] for a,b in zip(ordered,ordered[1:])), 'unconstrained fit violates ordering; do not apply'
 return result
if __name__=='__main__':
 mode=sys.argv[1]
 if mode=='fit': data={'baseline':summarize('train_base'),'perturbation':summarize('train_slow'),'paired_effect':paired('train_base','train_slow'),'fit':fit()}
 elif mode=='paired': data=paired(sys.argv[2],sys.argv[3])
 else: data=summarize(mode)
 path=OUT/(sys.argv[-1] if sys.argv[-1].endswith('.json') else mode+'_summary.json')
 path.write_text(json.dumps(data,indent=2)+'\n')
 print(path)
 if mode=='fit': print(json.dumps(data['fit'],indent=2))
 else: print(json.dumps(data,indent=2)[:2000])
