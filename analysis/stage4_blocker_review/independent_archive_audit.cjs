/* Independent raw Builder archive arithmetic; imports no report analyzer.
 * Usage: node analysis/stage4_blocker_review/independent_archive_audit.cjs PYTHON [OUTPUT_JSON]
 * Python is an explicit interpreter path; the embedded program uses only its standard library.
 * The source mirrors literal locked constraints and computes pooled facts and matched influence
 * standard errors independently. It does not rerun a simulation or produce certification.
 */
const fs = require('node:fs');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');
const initialHash = crypto.createHash('sha256').update(fs.readFileSync(__filename)).digest('hex');
const python = process.argv[2];
if (!python) throw new Error('Pass the Python 3 executable path as argument 1.');
let program = String.raw`
import json, math, pathlib, hashlib, collections, statistics
root=pathlib.Path('.')
summary=json.loads((root/'analysis/builder_dominance_followup/summary.json').read_text())
BASE=[35,35,35,35,35,35,35,35,38,35,35,35,35,38,35,35,45,45,45,45]
checks=0
def check(ok, label):
 global checks
 checks+=1
 if not ok: raise AssertionError(label)
def near(a,b,label):
 check((a is None and b is None) or (a is not None and b is not None and math.isclose(a,b,rel_tol=1e-11,abs_tol=1e-10)),label)
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def raw_ovr(v):
 s=sorted(v); return (78*sum(s)+75*sum(s[-8:])+40*sum(s[:6]))/2400
def metrics(rows):
 t=collections.Counter()
 for r in rows:
  for k,v in r.items():
   if type(v) in (int,float): t[k]+=v
 t['games']=len(rows)
 def ratio(n,d,m=1): return m*n/d if d>0 else None
 a={
 'effective_field_goal_percentage':ratio(t['field_goals_made']+.5*t['three_pointers_made'],t['field_goals_attempted'],100),
 'points_per_32_minutes':ratio(t['points'],t['seconds_played'],1920),
 'created_field_goals_per_100_touches':ratio(t['created_field_goals_made'],t['touches'],100),
 'turnovers_per_100_touches':ratio(t['turnovers'],t['touches'],100),
 'steals_per_100_on_court_defense_possessions':ratio(t['steals'],t['on_court_defense_possessions'],100),
 'blocks_per_100_on_court_defense_possessions':ratio(t['blocks'],t['on_court_defense_possessions'],100),
 'offensive_rebounds_per_100_on_court_offense_possessions':ratio(t['offensive_rebounds'],t['on_court_offense_possessions'],100),
 'defensive_rebounds_per_100_on_court_defense_possessions':ratio(t['defensive_rebounds'],t['on_court_defense_possessions'],100),
 'advantages_per_100_touches':ratio(t['advantages_created'],t['touches'],100),
 'team_margin_per_game':ratio(t['team_margin'],t['games']),
 'allowed_effective_field_goal_percentage':ratio(t['defended_makes']+.5*t['defended_three_makes'],t['defended_attempts'],100),
 'minutes_per_game':ratio(t['seconds_played'],t['games'],1/60),
 'points_per_game':ratio(t['points'],t['games']),
 'field_goal_attempts_per_32_minutes':ratio(t['field_goals_attempted'],t['seconds_played'],1920),
 'free_throw_attempts_per_32_minutes':ratio(t['free_throws_attempted'],t['seconds_played'],1920),
 'free_throw_percentage':ratio(t['free_throws_made'],t['free_throws_attempted'],100),
 'assists_per_32_minutes':ratio(t['assists'],t['seconds_played'],1920),
 'passes_per_100_touches':ratio(t['passes_completed'],t['touches'],100),
 'screens_per_32_minutes':ratio(t['screens_set'],t['seconds_played'],1920),
 'screen_advantages_per_32_minutes':ratio(t['screen_advantages_created'],t['seconds_played'],1920),
 'plus_minus_per_32_minutes':ratio(t['plus_minus'],t['seconds_played'],1920),
 'win_percentage':ratio(t['team_win'],t['games'],100)}
 return t,a
def primary_input(k,t):
 if k=='effective_field_goal_percentage': return t['field_goals_made']+.5*t['three_pointers_made'],t['field_goals_attempted'],100
 if k=='allowed_effective_field_goal_percentage': return t['defended_makes']+.5*t['defended_three_makes'],t['defended_attempts'],100
 if k=='team_margin_per_game': return t['team_margin'],t['games'],1
 if k=='points_per_32_minutes': return t['points'],t['seconds_played'],1920
 stems={'created_field_goals_per_100_touches':'created_field_goals_made','turnovers_per_100_touches':'turnovers','advantages_per_100_touches':'advantages_created'}
 if k in stems: return t[stems[k]],t['touches'],100
 stem=k.split('_per_100_')[0]
 den='on_court_offense_possessions' if stem=='offensive_rebounds' else 'on_court_defense_possessions'
 return t[stem],t[den],100
# Independent odd-degrees-of-freedom Student-t CDF, via integral of cos^14.
# This avoids the analyzer's incomplete-beta continued fraction entirely.
def t15_cdf(t):
 theta=math.atan(t/math.sqrt(15)); integral=theta
 for power in range(2,15,2):
  integral=math.sin(theta)*math.cos(theta)**(power-1)/power+(power-1)/power*integral
 return .5+math.gamma(8)/(math.sqrt(math.pi)*math.gamma(7.5))*integral
def t15_quantile(p):
 lo,hi=0.0,10.0
 for _ in range(80):
  mid=(lo+hi)/2
  if t15_cdf(mid)<p:lo=mid
  else:hi=mid
 return (lo+hi)/2
critical_ordinary=t15_quantile(.975)
critical_simultaneous=t15_quantile(1-.05/(2*374))
negative={'turnovers_per_100_touches','allowed_effective_field_goal_percentage'}
results={}; allseeds={}; allpairs=set(); allunique=set(); primary_checks=0
for label,start in [('validation_a',71000000),('validation_b',81000000)]:
 rows=[json.loads(l) for l in (root/'reports/builder_followup'/f'{label}.ndjson').read_text().splitlines() if l]
 s=summary['ranges'][label]; check(len(rows)==1184==s['games'],'count')
 metadata=json.loads((root/'analysis/builder_dominance_followup'/f'{label}.metadata.json').read_text())
 check(metadata['games']==1184 and metadata['errors']==[],'metadata')
 check(metadata['execution_head']=='07789d28f277a474ebec7df83d52c0564d0dbba0','execution')
 for d in [metadata['production_sha256'], metadata['instrument_sha256']]:
  for p,h in d.items(): check(sha(root/p.removeprefix('res://'))==h,'current source '+p)
 rawhash=sha(root/'reports/builder_followup'/f'{label}.ndjson')
 check(rawhash==next(h for p,h in summary['raw_sha256'].items() if label in p),'rawsha')
 g=collections.defaultdict(list); reference={}; identities=set()
 for r in rows:
  b=r['build']; values=b['ratings']; caps=b['caps']; bases=b['bases']; h,w,span,reach=b['body']
  family=b['family']; prospect=b['prospect']; q=r['quartet']; phase=r['phase']; cell=r['cell']
  check(r['range']==label and r['errors']==[] and r['reconciliation_errors']==[],'rowerrors')
  check(r['seed']==start+1000*cell+4*q+phase+1,'seed')
  check(r['home_subject']==(phase in (0,3)) and r['subject_opens']==(phase<2),'balance')
  check((r['build_id'],cell,q,phase) not in identities,'duplicates'); identities.add((r['build_id'],cell,q,phase))
  check(len(values)==len(caps)==len(bases)==20 and len(b['tendencies'])==10,'shape')
  check([66,70,74][family]<=h<=[74,78,82][family] and abs(w-math.floor(160+4.6*(h-72)+.5))<=22 and h-2<=span<=h+7 and reach==math.floor(.585*h+.720*span+.5),'body')
  check(sum(abs(a-c) for a,c in zip(bases,BASE))<=18 and abs(sum(bases)-sum(BASE))<=1 and all(abs(a-c)<=4 for a,c in zip(bases,BASE)),'redistribution')
  check(all(25<=v<=75 and base<=v<=cap and 40<=cap<=99 for v,base,cap in zip(values,bases,caps)),'attrs')
  cost=sum(sum(1 if dest<=59 else 2 if dest<=69 else 3 for dest in range(base+1,v+1)) for base,v in zip(bases,values))
  check(cost==[235,195,155][prospect]==b['ap_granted']==b['ap_spent'] and b['ap_remaining']==0 and b['confirmed'] and not b['preview_confirmable'],'AP')
  check(caps==b['initial_caps'] and b['maturity']==1 and all(1<=v<=5 for v in b['tendencies']),'caps/sliders')
  check(b['current_overall']==math.floor(min(99,max(25,raw_ovr(values)))+.5),'currentOVR')
  check(b['maximum_potential']==math.floor(min(99,max(25,raw_ovr(caps)))+.5),'capsOVR')
  check(r['points']==2*r['field_goals_made']+r['three_pointers_made']+r['free_throws_made']==r['ledger_points'] and r['ledger_attempts']==r['field_goals_attempted'] and r['ledger_touches']==r['touches'],'ledger')
  check(r['team_margin']==r['team_points']-r['opponent_points'] and r['team_win']==(r['team_margin']>0),'teamresults')
  check(r['seconds_played']>0 and r['touches']>0 and 0<r['on_court_offense_possessions']<=r['team_possessions'] and 0<r['on_court_defense_possessions']<=r['opponent_possessions'],'opportunity')
  check(r['defended_attempts']>=r['defended_makes']>=r['defended_three_makes'] and r['defended_points']==2*r['defended_makes']+r['defended_three_makes'] and sum(r['defended_contest_bands'].values())==r['defended_attempts'],'defense')
  check(r['possession_records']==r['possession_starts']==r['possession_ends'],'possessions')
  for k in ['teammate_signature','opponent_signature','ledger_sha256']: check(len(r[k])==64 and set(r[k])<=set('0123456789abcdef'),'hashformat')
  g[r['build_id']].append(r); allunique.add((label,r['build_id'],b['seed'])); allpairs.add((r['subject_roster'],r['opponent_roster']))
  if r['build_id']=='balanced_flat': reference[(cell,q,phase)]=r
 primary=[k for k,v in g.items() if v[0]['build']['primary']]
 check(len(primary)==18 and len(g)==22,'arms')
 for name,gr in g.items():
  cells=range(8) if name in primary else [0]
  check({(r['cell'],r['quartet'],r['phase']) for r in gr}=={(c,q,p) for c in cells for q in range(2) for p in range(4)},'coverage')
  check(len({r['seed'] for r in gr})==len(gr),'seedunique')
  t,m=metrics(gr)
  for k,v in s['summaries'][name]['raw'].items(): near(t[k],v,'raw '+name+k)
  for k,v in s['summaries'][name]['metrics'].items(): near(m[k],v,'metric '+name+k)
  near(statistics.mean(raw_ovr(r['build']['ratings']) for r in gr),s['summaries'][name]['raw_ovr_mean'],'rawOVRmean')
  for cell in cells:
   t,m=metrics([r for r in gr if r['cell']==cell])
   for k,v in s['cells'][name][str(cell)]['raw'].items(): near(t[k],v,'cellraw')
   for k,v in s['cells'][name][str(cell)]['metrics'].items(): near(m[k],v,'cellmetric')
  if name in primary:
   for r in gr:
    ref=reference[(r['cell'],r['quartet'],r['phase'])]
    check(all(r[k]==ref[k] for k in ['seed','variation','home_subject','subject_opens','context','subject_roster','opponent_roster','teammate_signature','opponent_signature']),'matchedcontrol')
    check(r['build']['prospect']==r['build']['family']==1,'primarydomain')
    if name.startswith('tendency_'): check(all(r['build'][k]==ref['build'][k] for k in ['ratings','caps','body','bases','ap_granted','ap_spent','seed']),'tendencyonly')
 base=g['balanced_flat']; bt,bm=metrics(base)
 for name, comps in s['primary_comparisons'].items():
  gr=g[name]; t,m=metrics(gr)
  for key,comp in comps.items():
   nt,d,mult=primary_input(key,t); bnt,bd,_=primary_input(key,bt); diff=m[key]-bm[key]
   near(diff,comp['difference'],'difference'); near(diff*(-1 if key in negative else 1),comp['favorable_difference'],'direction')
   near(nt,comp['left_numerator'],'numerator');near(d,comp['left_denominator'],'denominator');near(bnt,comp['right_numerator'],'basenum');near(bd,comp['right_denominator'],'baseden')
   influence=[]
   for c in range(8):
    for q in range(2):
     ct,_=metrics([r for r in gr if r['cell']==c and r['quartet']==q]); cbt,_=metrics([r for r in base if r['cell']==c and r['quartet']==q])
     nn,dd,_=primary_input(key,ct); bnn,bdd,_=primary_input(key,cbt)
     influence.append(mult*((nn-nt/d*dd)/(d/16)-(bnn-bnt/bd*bdd)/(bd/16)))
   se=statistics.stdev(influence)/4
   if 'standard_error' in comp:
    near(se,comp['standard_error'],'SE')
    for field,critical in [('interval',critical_ordinary),('simultaneous_interval',critical_simultaneous)]:
     near(diff-critical*se,comp[field][0],'interval low')
     near(diff+critical*se,comp[field][1],'interval high')
   primary_checks+=1
 mm={name:metrics(g[name])[1] for name in primary}
 keys=list(s['primary_comparisons'][primary[1]])
 def dom(a,b):
  ds=[(mm[a][k]-mm[b][k])*(-1 if k in negative else 1) for k in keys]
  return all(d>=0 for d in ds) and any(d>0 for d in ds)
 frontier=[name for name in primary if not any(dom(other,name) for other in primary if name!=other)]
 check(frontier==s['descriptive_frontier'],'frontier')
 for pair in s['descriptive_pairwise']:
  a=pair['left'];b=pair['right']; check(pair['right_descriptively_dominates']==dom(b,a) and pair['left_descriptively_dominates']==dom(a,b),'paretopair')
  for k,v in pair['right_minus_left_favorable'].items():near((mm[b][k]-mm[a][k])*(-1 if k in negative else 1),v,'pairdelta')
 check(len(s['descriptive_pairwise'])==153 and s['all_observable_simultaneous_superiority_vs_balanced']==[],'inconclusive')
 unique={(r['build_id'],r['build']['seed']) for r in rows};check(len(unique)==s['unique_build_draws']==s['creation_exhausted'],'draws')
 allseeds[label]={r['seed'] for r in rows}
 results[label]={'rows':len(rows),'primary_rows':sum(len(g[k]) for k in primary),'shared_seeds':len(allseeds[label]),'distinct_build_draws':len(unique),'frontier':len(frontier),'raw_sha256':rawhash,'interval_critical_values':sorted({round((v['simultaneous_interval'][1]-v['difference'])/v['standard_error'],10) for c in s['primary_comparisons'].values() for v in c.values() if v['simultaneous_interval'] is not None}), 'body_raw_ovr':{k:s['summaries'][k]['raw_ovr_mean'] for k in ['balanced_flat','body_small','body_large']}}
check(not(allseeds['validation_a'] & allseeds['validation_b']),'ranges disjoint')
result = {'independent_checks':checks,'primary_contrasts':primary_checks,'combined_unique_roster_pairs':len(allpairs),'distinct_build_draws':len(allunique),'ranges':results}
`;
const ovrProgram = String.raw`

# Optional OVR archive review: separate literal counts/formula/pooled/per-stratum
# statistics and independently resampled primary interventions, no analyzer imports.
builder_checks=checks
ovr_initial_aggregate_sha=sha(root/'analysis/ovr_truthfulness_followup/aggregate.json')
ovr_aggregate=json.loads((root/'analysis/ovr_truthfulness_followup/aggregate.json').read_text())
ARMS=['baseline','all20_plus10_toward_caps','scoring5_plus10_toward_caps']
COMPS=['high_school','college','development','overseas','top_domestic_pro']
COUNTS=['seconds_played','points','field_goals_made','field_goals_attempted','three_pointers_made','three_pointers_attempted','free_throws_made','free_throws_attempted','offensive_rebounds','defensive_rebounds','assists','steals','blocks','turnovers','personal_fouls','touches','passes_completed','screens_set','screen_advantages_created','off_ball_actions','advantages_created','created_field_goals_made','on_court_offense_possessions','on_court_defense_possessions','opponent_fga_on_court','opponent_fgm_on_court','on_court_defensive_misses','team_possessions','opponent_possessions','team_score','opponent_score','won']
PRIMARY=['team_margin','points_per32','field_goal_fraction','assists_per100_touches','turnovers_per100_touches','rebounds_per32','steals_blocks_per32']
OUTCOMES=PRIMARY[1:]+['opponent_field_goal_fraction_on_court']
def ovr_totals(rows):
 t={k:sum(r[k] for r in rows) for k in COUNTS}
 t.update(games=len(rows),team_margin=sum(r['team_margin'] for r in rows),raw_ovr_sum=sum(r['raw_ovr'] for r in rows),current_ovr_sum=sum(r['current_ovr'] for r in rows))
 return t
def ovr_metrics(t):
 def div(a,b,m=1):return m*a/b if b>0 else None
 return {'team_margin':div(t['team_margin'],t['games']),'team_win_fraction':div(t['won'],t['games']),'mean_minutes':div(t['seconds_played'],t['games']*60),'points_per32':div(t['points'],t['seconds_played'],1920),'points_per100_offense_possessions':div(t['points'],t['on_court_offense_possessions'],100),'field_goal_fraction':div(t['field_goals_made'],t['field_goals_attempted']),'effective_field_goal_fraction':div(t['field_goals_made']+.5*t['three_pointers_made'],t['field_goals_attempted']),'three_point_fraction':div(t['three_pointers_made'],t['three_pointers_attempted']),'assists_per100_touches':div(t['assists'],t['touches'],100),'turnovers_per100_touches':div(t['turnovers'],t['touches'],100),'advantages_per100_offense_possessions':div(t['advantages_created'],t['on_court_offense_possessions'],100),'rebounds_per32':div(t['offensive_rebounds']+t['defensive_rebounds'],t['seconds_played'],1920),'defensive_rebounds_per100_defense_possessions':div(t['defensive_rebounds'],t['on_court_defense_possessions'],100),'steals_blocks_per32':div(t['steals']+t['blocks'],t['seconds_played'],1920),'opponent_field_goal_fraction_on_court':div(t['opponent_fgm_on_court'],t['opponent_fga_on_court']),'fouls_per32':div(t['personal_fouls'],t['seconds_played'],1920),'mean_raw_ovr':div(t['raw_ovr_sum'],t['games']),'mean_current_ovr':div(t['current_ovr_sum'],t['games'])}
def hist(values):
 counts=collections.Counter(str(v) for v in values); ordered=sorted(values); n=len(values)
 return {'n':n,'min':ordered[0],'median':statistics.median(ordered),'max':ordered[-1],'counts':dict(counts),'count95plus':sum(v>=95 for v in values),'count96plus':sum(v>=96 for v in values),'count99':sum(v==99 for v in values),'share95plus':sum(v>=95 for v in values)/n}
def compare_hist(values,target):
 h=hist(values)
 for key,value in h.items():
  if isinstance(value,dict):check(value==target[key],'histogram frequencies')
  else:near(value,target[key],'histogram '+key)
def correlation(pairs):
 pp=[(x,y) for x,y in pairs if x is not None and y is not None and math.isfinite(x) and math.isfinite(y)]
 if len(pp)<3:return None
 xx=[p[0] for p in pp]; yy=[p[1] for p in pp]; mx=statistics.mean(xx);my=statistics.mean(yy)
 cov=sum((x-mx)*(y-my) for x,y in pp); vx=sum((x-mx)**2 for x in xx); vy=sum((y-my)**2 for y in yy)
 return cov/math.sqrt(vx*vy) if vx>0 and vy>0 else None
def pooled_check(rows,target):
 t=ovr_totals(rows);m=ovr_metrics(t)
 for key,v in target['raw'].items():near(t[key],v,'OVR pooled raw '+key)
 for key,v in target['normalized'].items():near(m[key],v,'OVR normalized '+key)
def quantile(values,p):
 ordered=sorted(values);x=(len(ordered)-1)*p;i=math.floor(x)
 return ordered[i]+(ordered[min(i+1,len(ordered)-1)]-ordered[i])*(x-i)
# Seven direct primary outcomes from an independently organized pooled vector.
BOOT_FIELDS=['team_margin','points','seconds_played','field_goals_made','field_goals_attempted','assists','touches','turnovers','offensive_rebounds','defensive_rebounds','steals','blocks']
def vector(rr):return [sum(r[k] for r in rr) for k in BOOT_FIELDS]
def primary_vector(v,games=96):
 mar,pts,sec,made,attempt,assist,touch,to,orb,drb,steal,block=v
 return [mar/games,1920*pts/sec,made/attempt,100*assist/touch,100*to/touch,1920*(orb+drb)/sec,1920*(steal+block)/sec]
def independent_bootstrap(rows,range_result):
 groups=collections.defaultdict(list)
 for r in rows:groups[r['cluster']].append(r)
 families=collections.defaultdict(list)
 for cluster,rr in groups.items():families[rr[0]['family']].append(cluster)
 vectors={cluster:{arm:vector([r for r in rr if r['arm']==arm]) for arm in ARMS[:2]} for cluster,rr in groups.items()}
 state=812; distributions=[[] for _ in PRIMARY]
 for draw in range(10000):
  base=[0]*12; target=[0]*12
  for stratum in families.values():
   for _ in stratum:
    state=(1664525*state+1013904223)&0xffffffff
    cluster=stratum[math.floor(state/4294967296*len(stratum))]
    for j in range(12):
     base[j]+=vectors[cluster][ARMS[0]][j];target[j]+=vectors[cluster][ARMS[1]][j]
  a=primary_vector(base);b=primary_vector(target)
  for j in range(7):distributions[j].append(b[j]-a[j])
 for j,key in enumerate(PRIMARY):
  row=range_result['all20_vs_baseline'][key]
  check(row['primary'] and row['resamples']==row['bootstrap_draws_with_defined_denominator']==10000 and row['source_player_clusters']==24,'primary bootstrap support')
  for field,tail in [('ci95',.025),('familywise_ci95',.05/(2*14))]:
   near(quantile(distributions[j],tail),row[field][0],'OVR bootstrap low')
   near(quantile(distributions[j],1-tail),row[field][1],'OVR bootstrap high')
ovr_results={}; natural=[]; fixture_payloads=[]; game_ranges={}; histogram_seeds=set()
for label,offset in [('A',0),('B',100000)]:
 manifest=json.loads((root/'reports'/f'ovr_manifest_{label}.json').read_text())
 check(manifest['unchanged_source_after_collection'] and not manifest['certified'] and not manifest['production_behavior_changed'],'OVR manifest status')
 check(manifest['protocol_sha256']==sha(root/'analysis/ovr_truthfulness_followup/protocol.json'),'OVR protocol hash')
 for p,h in manifest['production_sha256'].items():check(sha(root/p.removeprefix('res://'))==h,'OVR production hash')
 for key,p in {'audit':'calibration/harness/ovr_truthfulness_audit.gd','runner':'calibration/runners/run_ovr_truthfulness_followup.gd','tests':'tests/calibration/test_ovr_truthfulness_audit.gd'}.items():check(sha(root/p)==manifest['instrument_sha256'][key],'OVR instrument hash')
 for kind,output in manifest['outputs'].items():check(sha(root/output['path'].removeprefix('res://'))==output['sha256'],'OVR archive output hash')
 kind_rows={}
 for kind,expected in [('within',288),('catalog',800),('college',160)]:
  rows=[json.loads(l) for l in (root/'reports'/f'ovr_{kind}_{label}.ndjson').read_text().splitlines() if l];kind_rows[kind]=rows
  check(len(rows)==expected,'OVR raw count')
  seen=set()
  for r in rows:
   check(r['range']==label and r['experiment']==kind,'OVR raw tags')
   check(all(type(r[k]) is int and r[k]>=0 for k in COUNTS),'OVR integer counts')
   check(r['points']==2*r['field_goals_made']+r['three_pointers_made']+r['free_throws_made'] and r['field_goals_made']<=r['field_goals_attempted'] and r['three_pointers_made']<=r['three_pointers_attempted']<=r['field_goals_attempted'],'OVR shooting')
   check(r['ledger_touches']==r['touches'] and r['on_court_offense_possessions']<=r['team_possessions'] and r['on_court_defense_possessions']<=r['opponent_possessions'],'OVR opportunity')
   check(r['team_margin']==r['team_score']-r['opponent_score'] and r['won']==(r['team_margin']>0),'OVR results')
   check(len(r['values'])==20 and all(type(v) is int and 25<=v<=99 for v in r['values']),'OVR current vector')
   near(raw_ovr(r['values']),r['raw_ovr'],'OVR raw oracle')
   check(math.floor(raw_ovr(r['values'])+.5)==r['current_ovr'],'OVR display oracle')
   if r['caps'] is not None:
    check(len(r['caps'])==20 and all(40<=v<=99 for v in r['caps']),'OVR cap vector')
    check(math.floor(raw_ovr(r['caps'])+.5)==r['maximum_potential'],'OVR cap oracle')
   check(0<=r['slot']<4,'OVR slot')
   identity=(r['seed'],r['player_id'],r.get('arm'))
   check(identity not in seen,'OVR duplicate identity');seen.add(identity)
   if kind=='within':
    check(r['source_seed']==9800001+offset+r['cluster'] and r['seed']==9810001+offset+4*r['cluster']+r['slot'],'OVR within schedule')
    check(r['subject_home']==(r['slot'] in (0,3)) and r['subject_opens']==(r['slot']<2),'OVR within venue')
   elif kind=='catalog':
    check(r['seed']==9820001+offset+COMPS.index(r['competition'])*8+r['variation'] and r['cluster']==COMPS.index(r['competition'])*2+r['variation']//4 and r['slot']==r['variation']%4,'OVR catalog schedule')
   else:
    team_ordinal=int(r['player_id'].split('_')[1]);player_ordinal=int(r['player_id'].split('_p')[-1])
    check(r['seed']==9850001+offset+4*r['cluster']+r['slot'] and team_ordinal in (0,1) and r['career_seed']==9840001+offset+20*r['cluster']+10*team_ordinal+player_ordinal,'OVR college schedule')
    check(r['age']==18+r['class_year'] and r['snapshot_career_year']==r['class_year']+4 and r['creation_ap']==r['creation_spent'],'OVR chronological source')
  if kind=='within':
   groups=collections.defaultdict(list)
   for r in rows:groups[r['cluster']].append(r)
   check(len(groups)==24,'OVR source clusters')
   for cluster,rr in groups.items():
    check({(r['arm'],r['slot']) for r in rr}=={(arm,slot) for arm in ARMS for slot in range(4)},'OVR paired support')
    base=next(r for r in rr if r['arm']=='baseline')
    for r in rr:
     check(all(r[k]==base[k] for k in ['caps','body','tendencies','position','tactical_role','rotation_role','family','source_seed','teammates_sha256','opponent_sha256']),'OVR held-fixed source')
     before=r['intervention']['before'];after=r['intervention']['after'];selected=range(20) if r['arm']==ARMS[1] else range(5) if r['arm']==ARMS[2] else []
     check(before==base['values'] and after==r['values'] and after==[min(before[i]+10,r['caps'][i]) if i in selected else before[i] for i in range(20)],'OVR legal intervention vector')
     cost=sum(sum(1 if dest<=59 else 2 if dest<=69 else 3 if dest<=79 else 5 if dest<=89 else 8 if dest<=94 else 12 for dest in range(a+1,b+1)) for a,b in zip(before,after))
     check(cost==r['intervention']['ap_granted'] and r['intervention']['rating_points_applied']==sum(b-a for a,b in zip(before,after)) and r['intervention']['caps_unchanged'],'OVR intervention AP')
   for arm in ARMS:pooled_check([r for r in rows if r['arm']==arm],ovr_aggregate['within'][label]['arms'][arm])
   for family in ['guard','wing','big']:
    for arm in ARMS:pooled_check([r for r in rows if r['arm']==arm and r['family']==family],ovr_aggregate['within'][label]['by_family'][family]['arms'][arm])
   for contrast,arm in [('all20_vs_baseline',ARMS[1]),('scoring5_vs_baseline',ARMS[2])]:
    bm=ovr_metrics(ovr_totals([r for r in rows if r['arm']==ARMS[0]])); tm=ovr_metrics(ovr_totals([r for r in rows if r['arm']==arm]))
    for k,v in ovr_aggregate['within'][label][contrast].items():near(tm[k]-bm[k],v['difference'],'OVR contrast')
   independent_bootstrap(rows,ovr_aggregate['within'][label])
  else:
   game_groups=collections.defaultdict(list);player_groups=collections.defaultdict(list)
   for r in rows:
    game_groups[r['seed']].append(r)
    key=(r['competition'],r['cluster'],r['player_id']) if kind=='college' else (r['competition'],r['cluster'],r['roster_variation'],r['player_id'].split('_p')[-1])
    player_groups[key].append(r)
   check(all(len(rr)==20 and len({r['player_id'] for r in rr})==20 for rr in game_groups.values()),'OVR population game coverage')
   players=[]
   for key,rr in player_groups.items():
    expected_exposures=8 if kind=='catalog' and key[2]==0 and key[1]%2==0 else 4
    check(len(rr)==expected_exposures and collections.Counter(r['slot'] for r in rr)=={slot:expected_exposures//4 for slot in range(4)} and all(r['values']==rr[0]['values'] for r in rr),'OVR player quartet')
    t=ovr_totals(rr);m=ovr_metrics(t);p=dict(rr[0]);p['metrics']=m;p['totals']=t
    p['minute_stratum']='under10' if m['mean_minutes']<10 else '10to20' if m['mean_minutes']<20 else '20plus'
    p['opportunity_stratum']='under10touches' if t['touches']/len(rr)<10 else '10to25touches' if t['touches']/len(rr)<25 else '25plustouches';players.append(p)
   target=ovr_aggregate['population_relationships'][kind+'_'+label]
   check(len(players)==target['overall']['players'],'OVR population player aggregates')
   def relationship_check(pp,record):
    for outcome in OUTCOMES:near(correlation([(p['raw_ovr'],p['metrics'][outcome]) for p in pp]),record['correlation'][outcome],'OVR correlation')
    check(len(pp)==record['players'],'OVR stratum players')
    for k,v in record['raw_counts'].items():
     near(sum(p['totals']['games'] for p in pp) if k=='player_game_exposures' else sum(p['totals'][k] for p in pp),v,'OVR aggregate exposures')
   relationship_check(players,target['overall'])
   for dimension, strata in target['strata'].items():
    for value,record in strata.items():relationship_check([p for p in players if str(p[dimension])==value],record)
   for dimension,record in target['within_strata_demeaned'].items():
    dim_keys=['competition','position','tactical_role','rotation_role'] if dimension=='joint_competition_position_tactical_rotation' else [dimension]
    groups=collections.defaultdict(list)
    for p in players:groups[tuple(p[k] for k in dim_keys)].append(p)
    for outcome,reported in record.items():
     pairs=[]
     for pp in groups.values():
      good=[p for p in pp if p['metrics'][outcome] is not None]
      if not good or (len(dim_keys)>1 and len(good)<2):continue
      x=statistics.mean(p['raw_ovr'] for p in good);y=statistics.mean(p['metrics'][outcome] for p in good)
      pairs.extend((p['raw_ovr']-x,p['metrics'][outcome]-y) for p in good)
     near(correlation(pairs),reported['correlation'] if isinstance(reported,dict) else reported,'OVR demeaned correlation')
     if isinstance(reported,dict):check(len(pairs)==reported['player_observations'],'OVR joint support')
 h=json.loads((root/'reports'/f'ovr_histograms_{label}.json').read_text())
 check(len(h['fixture_rows'])==5850 and len(h['natural_rows'])==1000,'OVR histogram coverage')
 check({r['career_seed'] for r in h['natural_rows']}==set(range(9860001+offset,9861001+offset)),'OVR histogram schedule')
 fixture_payloads.append(h['fixture_rows'])
 for r in h['fixture_rows']:check(math.floor(raw_ovr(r['values'])+.5)==r['current_ovr'],'OVR fixture oracle')
 for r in h['natural_rows']:
  check(r['career_seed'] not in histogram_seeds,'OVR duplicate career seed');histogram_seeds.add(r['career_seed'])
  for key,value in [('starting_values','starting_current'),('exact_caps','maximum_potential'),('peak_values','peak_current'),('final_values','final_current')]:check(math.floor(raw_ovr(r[key])+.5)==r[value],'OVR natural '+key)
  check(len(r['college_values'])==len(r['college_current'])==len(r['college_ages']),'OVR college histogram lengths')
  for values,ovr in zip(r['college_values'],r['college_current']):check(math.floor(raw_ovr(values)+.5)==ovr,'OVR natural college oracle')
 natural.extend(h['natural_rows'])
 game_ranges[label]={r['seed'] for rows in kind_rows.values() for r in rows}
 ovr_results[label]={'within_rows':len(kind_rows['within']),'catalog_player_game_rows':len(kind_rows['catalog']),'college_player_game_rows':len(kind_rows['college']),'unique_gameplay_seeds':len(game_ranges[label]),'manifest_sha256':sha(root/'reports'/f'ovr_manifest_{label}.json'),'raw_sha256':{kind:output['sha256'] for kind,output in manifest['outputs'].items()},'execution_head':manifest['execution_head']}
check(not game_ranges['A']&game_ranges['B'],'OVR gameplay ranges disjoint')
check(fixture_payloads[0]==fixture_payloads[1],'OVR shared fixture population counted once')
target=ovr_aggregate['histograms'];check(target['natural_careers']==2000,'OVR natural count')
for key,field in [('starting_current','starting_current'),('maximum_potential','maximum_potential'),('peak_current','peak_current'),('final_current','final_current')]:compare_hist([r[field] for r in natural],target[key])
for dimension in ['prospect','family','path']:
 for value,record in target['by_'+dimension].items():
  rr=[r for r in natural if r[dimension]==value];check(len(rr)==record['seed_count'],'OVR natural stratum')
  for key,field in [('starting','starting_current'),('potential','maximum_potential'),('peak','peak_current')]:compare_hist([r[field] for r in rr],record[key])
for competition,record in target['fixture_by_competition'].items():compare_hist([r['current_ovr'] for r in fixture_payloads[0] if r['competition']==competition],record['current'])
age_groups=collections.defaultdict(list)
for r in natural:
 age_groups['freshman_start/14'].append(r['starting_current'])
 for i,(age,ovr) in enumerate(zip(r['all_season_ages'],r['all_season_current'])):
  phase='high_school' if i<4 else 'college' if i<7 else 'professional_career_harness';age_groups[phase+'/'+str(age)].append(ovr)
check(set(age_groups)==set(target['by_age_and_phase']),'OVR age phase support')
for key,values in age_groups.items():compare_hist(values,target['by_age_and_phase'][key])
check(ovr_initial_aggregate_sha==sha(root/'analysis/ovr_truthfulness_followup/aggregate.json'),'OVR aggregate changed during independent audit')
result['independent_builder_checks']=builder_checks
result['ovr']={'additional_independent_checks':checks-builder_checks,'ranges':ovr_results,'natural_careers':len(natural),'fixture_population_states_counted_once':len(fixture_payloads[0]),'primary_bootstrap_intervals_independently_replayed':14,'stratified_correlations_and_demeaning_reconciled':True,'aggregate_sha256':sha(root/'analysis/ovr_truthfulness_followup/aggregate.json'),'mature_world_rarity_tested':False}
result['independent_checks']=checks
`;
if (process.argv.includes('--with-ovr')) program += ovrProgram;
program += '\nprint(json.dumps(result,indent=2))\n';
const run = spawnSync(python, ['-'], {input: program, encoding:'utf8', maxBuffer:4*1024*1024});
if (run.error) throw run.error;
if (run.status !== 0) { process.stderr.write(run.stderr || run.stdout); process.exit(run.status || 1); }
const result = JSON.parse(run.stdout);
result.auditor_sha256 = crypto.createHash('sha256').update(fs.readFileSync(__filename)).digest('hex');
if (result.auditor_sha256 !== initialHash) throw new Error('Auditor source changed during execution.');
result.embedded_program_sha256 = crypto.createHash('sha256').update(program).digest('hex');
result.command = [process.execPath, __filename, python, ...process.argv.slice(3)];
result.no_certification = true;
if (process.argv[3]) fs.writeFileSync(process.argv[3], JSON.stringify(result,null,2)+'\n');
process.stdout.write(JSON.stringify(result,null,2)+'\n');
