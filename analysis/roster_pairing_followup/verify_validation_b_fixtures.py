"""Read-only Validation B construction audit; no outcome analysis."""
import json,collections,hashlib,subprocess
from pathlib import Path
if not __debug__:
 raise RuntimeError('Run without -O/PYTHONOPTIMIZE; this verifier uses assertions')
r=Path(__file__).resolve().parents[2]; base=Path(__file__).resolve().parent
audit=json.loads((base/'construction_audit.json').read_text(encoding='utf-8-sig'))
rowsout=[]
for c in audit['competitions']:
 comp=c['competition']; states={x['variation']:x['ratings'] for x in c['roster_states']}
 for version in ('baseline','candidate'):
  armdata={}
  for arm in ('home','neutral'):
   label=f'validation_b_{version}_{arm}_{comp}'
   path=base/'reports'/f'roster_raw_{label}_{comp}.json'
   data=json.loads(path.read_text(encoding='utf-8-sig')); rec=json.loads((base/'processes'/f'{label}.json').read_text(encoding='utf-8-sig'))
   assert hashlib.sha256(path.read_bytes()).hexdigest()==rec['raw_sha256']
   assert len(data['rows'])==468
   counts={s:collections.Counter() for s in ('home','away')};cross=collections.Counter();cells=set();ladder=set();diags=[]
   for offset,row in enumerate(data['rows']):
    v=32760000+offset;assert row['variation']==v and row['seed']==v+1 and row['block']==v//4
    assert row['opening_home']==(v%2==0)
    if version=='candidate':
     k=v//4;A=k%117;B=(2*A+k//117)%117;h,b=(B,A) if v%4 in (1,2) else (A,B)
    else:h,b=2*v%117,(2*v+1)%117
    for side,state in [('home',h),('away',b)]:
     assert row[side+'_strength']['attribute_vectors']==states[state],(label,v,side,state)
     counts[side][state]+=1;cross[(side,state,row['opening_home'])]+=1
    cells.add((h,b));ladder.add((h%13,b%13))
    if h==b:diags.append(v)
   assert all(len(counts[s])==117 and set(counts[s].values())=={4} for s in counts)
   if version=='candidate':
    assert len(cross)==468 and set(cross.values())=={2}
    assert len(diags)==4 and len(cells)==231 and len(ladder)==25
    assert len({v//4 for v in diags})==1
   armdata[arm]=data['rows']
   rowsout.append(dict(cell=label,rows=468,all_rating_vectors_match=True,home_states=117,away_states=117,appearances_each_side=4,opener_home=sum(x['opening_home'] for x in data['rows']),diagonal_variations=diags,ordered_cells=len(cells),ladder_cells=len(ladder)))
  assert [(x['home_strength'],x['away_strength'],x['opening_home']) for x in armdata['home']]==[(x['home_strength'],x['away_strength'],x['opening_home']) for x in armdata['neutral']]
source_diff=subprocess.check_output(['git','diff','--name-only','a15bdd00debf2e75925c9376ff316650b46b516b','--','src','calibration','tests','tools','project.godot','BALANCE_SPEC.md','SIMULATION_SPEC.md'],text=True,cwd=r)
assert not source_diff.strip(),source_diff
print(json.dumps({'verdict':'VALIDATION B FIXTURE CONSTRUCTION ACCEPT','cells':rowsout,'source_drift_since_gate':False,'scope':'No outcome fields analyzed; Validation B construction only'},indent=2))

