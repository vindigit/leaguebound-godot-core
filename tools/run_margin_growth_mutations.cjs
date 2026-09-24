/* Usage: node tools/run_margin_growth_mutations.cjs GODOT_EXE [OUTPUT_DIRECTORY]
 * Every mutant runs in a fresh-process isolated copy. A parse error, runtime
 * error, missing summary, unexpected case count, or non-assertion exit is not a
 * kill. The expensive seeded-ledger observation test remains in the full gate;
 * these mutations target the independent arithmetic and corruption fixtures.
 */
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const crypto = require('node:crypto');
const cp = require('node:child_process');
const root = path.resolve(__dirname, '..');
const godot = path.resolve(process.argv[2] || '');
if (!process.argv[2] || !fs.statSync(godot).isFile()) throw new Error('Provide an existing Godot executable');
const output = path.resolve(root, process.argv[3] || 'analysis/margin_growth_followup/mutations');
if (!output.startsWith(root + path.sep)) throw new Error('Output must remain under repository');
fs.mkdirSync(output, {recursive:true});
const isolated = fs.mkdtempSync(path.join(os.tmpdir(), 'leaguebound-margin-growth-'));
for (const name of ['project.godot','src','tests','calibration','tools','addons']) {
  fs.cpSync(path.join(root,name), path.join(isolated,name), {recursive:true});
}
const harness = 'calibration/harness/margin_growth_audit.gd';
const sourceFiles = [harness,'tests/fixtures/margin_growth_fixtures.gd','tests/calibration/test_margin_growth_audit.gd','tests/calibration/test_margin_growth_live.gd'];
const sha = p => crypto.createHash('sha256').update(fs.readFileSync(p)).digest('hex');
const sourceHashes = Object.fromEntries(sourceFiles.map(f => [f,sha(path.join(root,f))]));
const metadata = {
  source_commit: cp.execFileSync('git',['-C',root,'rev-parse','HEAD'], {encoding:'utf8',windowsHide:true}).trim(),
  started_utc: new Date().toISOString(), isolated_copy: isolated,
  godot: cp.execFileSync(godot,['--version'], {encoding:'utf8',windowsHide:true}).trim(),
  source_sha256: sourceHashes, results: [],
};
function writeResults() { fs.writeFileSync(path.join(output,'results.json'),JSON.stringify(metadata,null,2)+'\n'); }
function run(id,args,expectSummary) {
  const result=cp.spawnSync(godot,args,{cwd:isolated,encoding:'utf8',windowsHide:true,timeout:args.includes('--import') ? 900000 : 240000,maxBuffer:32*1024*1024});
  const log=(result.stdout || '')+(result.stderr || '');
  fs.writeFileSync(path.join(output,id+'.log'),log);
  const clean=log.replace(/\x1b\[[0-9;]*[A-Za-z]/g,'');
  if (result.error) throw result.error;
  if (/SCRIPT ERROR|Parse Error|No test cases found/.test(clean)) throw new Error(id+' invalid execution');
  const summary=/Overall Summary: ([^\r\n]+)/.exec(clean)?.[1];
  if (expectSummary && !summary) throw new Error(id+' missing summary');
  return {id,exit_code:result.status,summary:summary || ''};
}
const imported=run('import',['--headless','--path',isolated,'--import'],false);
if (imported.exit_code!==0) throw new Error('isolated import failed');
const args=['--headless','--path',isolated,'-s','addons/gdUnit4/bin/GdUnitCmdTool.gd','--ignoreHeadlessMode','-a','tests/calibration/test_margin_growth_audit.gd','-c'];
const baseline=run('baseline',args,true);
metadata.results.push(baseline);writeResults();
if (baseline.exit_code!==0 || !/9 test cases \| 0 errors \| 0 failures/.test(baseline.summary)) throw new Error('baseline not green at expected nine cases');
const mutants=[
  {id:'turnover_sign',old:'"turnovers": -efficiency_sum * turnover_delta,',replacement:'"turnovers": efficiency_sum * turnover_delta,'},
  // This one preserves the total identity by moving ORB into the residual.
  {id:'rebound_hidden_in_residual',old:'var rebound_delta: float = (home["offensive_rebounds"] as float) - (away["offensive_rebounds"] as float)',replacement:'var rebound_delta: float = 0.0'},
  {id:'ft_event_points_schema',old:'return {"points": 1, "free_throws_made": 1, "free_throws_attempted": 1}',replacement:'return {"points": event.points, "free_throws_made": 1, "free_throws_attempted": 1}'},
  {id:'ft_awards_as_makes',old:'"free_throws": (home["free_throws_made"] as float) - (away["free_throws_made"] as float),',replacement:'"free_throws": (home["free_throws_awarded"] as float) - (away["free_throws_awarded"] as float),'},
  {id:'blocked_expected_points',old:'var probability: float = 0.0',replacement:'var probability: float = 0.5'},
  {id:'innovation_removed',old:'result["shooting_innovation"] = ((home["field_points"] as float) - (home["expected_field_points"] as float)) - ((away["field_points"] as float) - (away["expected_field_points"] as float))',replacement:'result["shooting_innovation"] = 0.0'},
  {id:'late_boundary_excluded',old:'clock_ms <= LATE_MS:',replacement:'clock_ms < LATE_MS:'},
  {id:'college_native_periods_as_quarters',old:'return mini(3, (adjusted * 4 / (duration * rules.regulation_periods) as int))',replacement:'return mini(3, period - 1 + 0 * adjusted)'},
  {id:'drop_straddled_clock_split',old:'record.end_clock_ms < LATE_MS:',replacement:'record.end_clock_ms < 0:'},
  {id:'offensive_rebound_extra_possession',old:'var changes: Dictionary = {"possessions": 1, "live_ms": record.start_clock_ms - record.end_clock_ms}',replacement:'var changes: Dictionary = {"possessions": 1 + record.offensive_rebounds, "live_ms": record.start_clock_ms - record.end_clock_ms}'},
  {id:'coverage_accepts_zero',old:'if (coverage.get(key, 0) as int) <= 0:',replacement:'if (coverage.get(key, 0) as int) < 0:'},
  {id:'period_score_check_bypassed',old:'if index >= scores.size() or scores[index] != (periods[index][side]["points"] as int):',replacement:'if index >= scores.size():'},
  {id:'nan_probability_accepted',old:'if not is_finite(probability) or probability < 0.0 or probability > 1.0:',replacement:'if probability < 0.0 or probability > 1.0:'},
  {id:'shot_shooter_linkage_bypassed',old:' or attempt.primary_player_id != outcome.primary_player_id',replacement:''},
  {id:'shot_clock_linkage_bypassed',old:' or attempt.clock_ms != outcome.clock_ms',replacement:''},
  {id:'shot_period_linkage_bypassed',old:' or attempt.period != outcome.period',replacement:''},
];
for (const mutant of mutants) {
  const file=path.join(isolated,harness);
  const original=fs.readFileSync(file);
  const normalized=original.toString('utf8').replaceAll('\r\n','\n');
  if (normalized.split(mutant.old).length!==2) throw new Error(mutant.id+' must match exactly once');
  try {
    fs.writeFileSync(file,normalized.replace(mutant.old,mutant.replacement));
    const record=run(mutant.id,args,true);
    metadata.results.push(record);writeResults();
    if (record.exit_code!==100 || !/9 test cases \| 0 errors \| [1-9][0-9]* failures/.test(record.summary)) throw new Error(mutant.id+' survived or failed without assertion evidence');
    process.stdout.write(mutant.id+' killed\n');
  } finally { fs.writeFileSync(file,original); }
}
for (const file of sourceFiles) {
  if (sha(path.join(root,file))!==sourceHashes[file] || sha(path.join(isolated,file))!==sourceHashes[file]) throw new Error('source changed during mutation run: '+file);
}
metadata.killed=mutants.length;
metadata.finished_utc=new Date().toISOString();
writeResults();
process.stdout.write(JSON.stringify({killed:metadata.killed,results:path.join(output,'results.json')})+'\n');
