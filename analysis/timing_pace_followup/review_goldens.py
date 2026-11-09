"""Inspect archived golden ledgers; results are evidence, not regenerated hashes."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parent
NAMES=['regulation','overtime','offensive_rebound','foul_free_throw','substitution_foul_out','late_game']
def events(path):
 return [line.split('|') for line in path.read_text(encoding='utf-8-sig').splitlines() if len(line.split('|'))==17 and line.split('|')[1].isdigit()]
result={}
for name in NAMES:
 before=events(ROOT/f'golden_before_{name}.txt');after=events(ROOT/f'golden_timing_{name}.txt')
 first=next(((a,b) for a,b in zip(before,after) if a!=b),None)
 result[name]={'comparison':'same original fixture/seed; overtime replacement documented separately',
  'before_events':len(before),'after_events':len(after),'first_divergence':{'before':first[0],'after':first[1]} if first else None}
# one_and_one_match has bonus from foul1 until foul40, reset each period.
ledger=events(ROOT/'golden_timing_late_game.txt');counts={};last_foul=None;trips=[]
for i,e in enumerate(ledger):
 if e[4]=='period_started': counts={}
 if e[4]=='foul':
  counts[e[5]]=counts.get(e[5],0)+1;last_foul=e
 if e[4]=='free_throw_awarded' and last_foul and last_foul[12]=='non_shooting_defensive' and 1<=counts[last_foul[5]]<40:
  outcomes=[]
  for n in ledger[i+1:]:
   if n[4] in ['free_throw_made','free_throw_missed']:
    outcomes.append(n)
   elif n[4] not in ['check_in','check_out']:
    break
  assert outcomes and int(e[15])==2
  assert len(outcomes)==(2 if outcomes[0][4]=='free_throw_made' else 1)
  assert all(n[3]==e[3] for n in outcomes)
  trips.append({'award_sequence':int(e[1]),'team_fouls':counts[last_foul[5]],'first_made':outcomes[0][4]=='free_throw_made','attempts':len(outcomes)})
assert trips
result['late_game']['verified_one_and_one_trips']=trips
ledger=events(ROOT/'golden_timing_substitution_foul_out.txt')
links=[]
for i,e in enumerate(ledger):
 if e[4]=='foul_out':
  linked=next((n for n in ledger[i+1:] if n[4]=='check_out' and n[8]==e[8] and n[3]==e[3]),None)
  assert linked is not None
  links.append({'foulout':int(e[1]),'checkout':int(linked[1]),'player':e[8]})
assert links
result['substitution_foul_out']['linked_checkouts']=links
(ROOT/'golden_review.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({n: {'first_event': result[n]['first_divergence']['after'][1:5] if result[n]['first_divergence'] else None} for n in NAMES},indent=2))
print('one_and_one_trips',len(trips),'linked_foulouts',len(links))
