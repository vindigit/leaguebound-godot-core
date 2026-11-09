/* Isolated report-instrument mutation proof. No main worktree edits.
 * node tools/run_builder_dominance_mutations.cjs GODOT_EXE PYTHON_EXE
 * Crashes, parse errors, or unrelated failures are invalid; each mutant must
 * fail its declared regression assertion after a clean focused baseline.
 */
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const root = path.resolve(__dirname,'..');
const godot = process.argv[2], python = process.argv[3];
if (!godot || !python || !fs.statSync(godot).isFile() || !fs.statSync(python).isFile()) throw new Error('Existing Godot and Python executables required');
const output = path.join(root,'analysis/builder_dominance_followup/mutations');
fs.mkdirSync(output,{recursive:true});
const isolated = fs.mkdtempSync(path.join(os.tmpdir(),'leaguebound-builder-dominance-'));
for (const name of ['project.godot','src','tests','calibration','tools','addons']) fs.cpSync(path.join(root,name),path.join(isolated,name),{recursive:true});
fs.cpSync(path.join(root,'analysis/builder_dominance_followup'),path.join(isolated,'analysis/builder_dominance_followup'),{recursive:true});
const fixture = 'calibration/harness/builder_dominance_fixtures.gd';
const audit = 'calibration/harness/builder_dominance_audit.gd';
const analyzer = 'analysis/builder_dominance_followup/analyze.py';
const owned = [fixture,audit,analyzer,'calibration/runners/run_builder_dominance_followup.gd','tests/calibration/test_builder_dominance_followup.gd','analysis/builder_dominance_followup/test_analysis.py'];
const sha = p=>crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const metadata = {started_utc:new Date().toISOString(),execution_head:cp.execFileSync('git',['-C',root,'rev-parse','HEAD'],{encoding:'utf8',windowsHide:true}).trim(),
  isolated_directory:isolated,source_sha256:Object.fromEntries(owned.map(p=>[p,sha(path.join(root,p))])),results:[]};
function save(){fs.writeFileSync(path.join(output,'results.json'),JSON.stringify(metadata,null,2)+'\n');}
function run(id,exe,args){
 const result=cp.spawnSync(exe,args,{cwd:isolated,encoding:'utf8',windowsHide:true,timeout:300000,maxBuffer:16*1024*1024});
 const log=((result.stdout||'')+(result.stderr||'')).replace(/\x1b\[[0-9;]*[A-Za-z]/g,'');
 fs.writeFileSync(path.join(output,id+'.log'),log);
 if(result.error)throw result.error;
 if(/SCRIPT ERROR|Parse Error|No test cases found|Assertion failed:/.test(log))throw new Error(id+' invalid execution, crash or parse failure');
 return {id,exit_code:result.status,log};
}
function record(r){const item={...r};delete item.log;metadata.results.push(item);save();}
const args=['--headless','--path',isolated,'-s','addons/gdUnit4/bin/GdUnitCmdTool.gd','--ignoreHeadlessMode','-a','tests/calibration/test_builder_dominance_followup.gd','-c'];
const pyargs=['analysis/builder_dominance_followup/test_analysis.py'];
const imported=run('import',godot,['--headless','--path',isolated,'--import']);
if(imported.exit_code!==0)throw new Error('isolated import failed');
for(const [id,exe,argv,summary] of [['gd_baseline',godot,args,/Overall Summary: 10 test cases \| 0 errors \| 0 failures/],['py_baseline',python,pyargs,/Ran 10 tests[\s\S]+OK/]]){
 const result=run(id,exe,argv);record(result);if(result.exit_code!==0||!summary.test(result.log))throw new Error(id+' not clean');
}
const mutants = [
 {id:'spent_record_unchecked',file:fixture,old:'or record["ap_spent"] != cost \\',replacement:'or false \\',test:'test_independent_validator_rejects_ap_economics_and_cap_corruptions'},
 {id:'seeded_caps_unchecked',file:fixture,old:'replay.bases() != bases or replay.caps.values() != caps:',replacement:'replay.bases() != bases:',test:'test_independent_validator_rejects_ap_economics_and_cap_corruptions'},
 {id:'standing_reach_unchecked',file:fixture,old:'if body[3] != int(roundf(float(body[0] as int) * 0.585 + float(body[2] as int) * 0.720)):',replacement:'if false:',test:'test_independent_validator_rejects_shape_body_and_tendency_corruptions'},
 {id:'duplicate_seed_unchecked',file:audit,old:'if seeds.has(row["seed"]):',replacement:'if false:',test:'test_schedule_rejects_duplicates_incomplete_quartets_and_venue_bias'},
 {id:'incomplete_quartet_unchecked',file:audit,old:'if rows.size() != 4 or phases.size() != 4:',replacement:'if false:',test:'test_schedule_rejects_duplicates_incomplete_quartets_and_venue_bias'},
 {id:'venue_balance_unchecked',file:audit,old:'if row["home_subject"] != (phase == 0 or phase == 3) or row["subject_opens"] != (phase < 2):',replacement:'if false:',test:'test_schedule_rejects_duplicates_incomplete_quartets_and_venue_bias'},
 {id:'defended_denominator_unchecked',file:audit,old:'if row["defended_makes"] > row["defended_attempts"] or row["defended_three_makes"] > row["defended_makes"]:',replacement:'if false:',test:'test_denominator_and_score_corruptions_fail_for_intended_reason'},
 {id:'ledger_touches_unchecked',file:audit,old:'or row["ledger_touches"] != row["touches"]:',replacement:'or false:',test:'test_denominator_and_score_corruptions_fail_for_intended_reason'},
 {id:'python_pooled_ratio_as_mean',file:analyzer,old:'multiplier*numerator(t, terms)/d if d > 0 else None',replacement:'multiplier*numerator(t, terms)/t["games"] if d > 0 else None',test:'test_sum_ratio_uses_opportunities_not_mean_game_percentages',python:true},
 {id:'python_turnover_direction_reversed',file:analyzer,old:'({"turnovers": 1}, "touches", 100, -1)',replacement:'({"turnovers": 1}, "touches", 100, 1)',test:'test_primary_metric_direction_and_zero_denominator',python:true},
 {id:'python_multiplicity_omits_validation_range',file:analyzer,old:'FAMILYWISE_COMPARISONS = 17 * 11 * 2',replacement:'FAMILYWISE_COMPARISONS = 17 * 11',test:'test_matched_cluster_covariance_and_familywise_intervals',python:true},
 {id:'python_venue_opener_unchecked',file:analyzer,old:'if r["home_subject"] != (r["phase"] in [0,3]) or r["subject_opens"] != (r["phase"] in [0,1]):',replacement:'if False:',test:'test_duplicate_seeds_missing_coverage_and_venue_bias_rejected',python:true},
 {id:'python_tendency_facts_unchecked',file:analyzer,old:'if build.startswith("tendency_"):',replacement:'if False:',test:'test_tendency_facts_and_teammate_control_corruptions_rejected',python:true},
 {id:'python_uncertainty_as_independent_events',file:analyzer,old:'statistics.stdev(influences)/math.sqrt(n)',replacement:'statistics.stdev(influences)/math.sqrt(len(left))',test:'test_matched_cluster_covariance_and_familywise_intervals',python:true},
];
for(const m of mutants){
 const target=path.join(isolated,m.file), original=fs.readFileSync(target,'utf8');
 if(original.split(m.old).length!==2)throw new Error(m.id+' mutation target not unique');
 fs.writeFileSync(target,original.replace(m.old,m.replacement));
 let result;
 try{result=run(m.id,m.python?python:godot,m.python?pyargs:args);}finally{fs.writeFileSync(target,original);}
 if(result.exit_code===0)throw new Error(m.id+' survived');
 if(m.python){
   if(!result.log.includes('FAIL: '+m.test)||/ERROR: |Traceback[^]*NameError|SyntaxError|KeyError/.test(result.log))throw new Error(m.id+' did not fail intended assertion');
 } else {
   if(!result.log.includes('> '+m.test+' FAILED')||!/Overall Summary: 10 test cases \| 0 errors \| [1-9]/.test(result.log))throw new Error(m.id+' did not fail intended regression assertion');
 }
 record({...result,intended_test:m.test,killed:true});console.log(m.id+' KILLED: '+m.test);
}
for(const [id,exe,argv,summary] of [['gd_restored',godot,args,/Overall Summary: 10 test cases \| 0 errors \| 0 failures/],['py_restored',python,pyargs,/Ran 10 tests[\s\S]+OK/]]){
 const result=run(id,exe,argv);record(result);if(result.exit_code!==0||!summary.test(result.log))throw new Error(id+' restored suite not clean');
}
for(const p of owned)if(metadata.source_sha256[p]!==sha(path.join(root,p)))throw new Error('main source changed during isolated proof');
metadata.completed_utc=new Date().toISOString();metadata.mutants_killed=mutants.length;save();
console.log('Builder report mutation proof: '+mutants.length+' intended assertion kills; clean before/after');
