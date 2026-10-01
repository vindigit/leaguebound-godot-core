/* Usage: node tools/run_ovr_analysis_mutations.cjs [OUTPUT_DIRECTORY]
 * Actual analyzer mutations in isolated files. Expected named AssertionError
 * failure is required; syntax errors, crashes, and different reasons fail.
 */
'use strict';
const fs = require('node:fs'), path = require('node:path'), os = require('node:os');
const crypto = require('node:crypto'), cp = require('node:child_process');
const root = path.resolve(__dirname, '..'), output = path.resolve(root, process.argv[2] || 'analysis/ovr_truthfulness_followup/analysis_mutations');
if (!output.startsWith(root + path.sep)) throw new Error('Output must remain under repository');
fs.mkdirSync(output, {recursive: true});
const isolated = fs.mkdtempSync(path.join(os.tmpdir(), 'leaguebound-ovr-analysis-'));
const sourceRel = 'analysis/ovr_truthfulness_followup/analyze.cjs', testRel = 'tests/tooling/test_ovr_truthfulness_analysis.cjs';
for (const file of [sourceRel, testRel]) {
  fs.mkdirSync(path.dirname(path.join(isolated, file)), {recursive: true});
  fs.copyFileSync(path.join(root, file), path.join(isolated, file));
}
const hash = f => crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const hashes = Object.fromEntries([sourceRel, testRel].map(f => [f, hash(path.join(root, f))]));
const testCount = (fs.readFileSync(path.join(root,testRel),'utf8').match(/cases\.\w+\s*=\s*\(\)\s*=>/g)||[]).length;
const metadata = {source_commit: cp.execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], {encoding: 'utf8', windowsHide: true}).trim(),
  source_sha256: hashes, focused_test_count:testCount, node_version: process.version, results: [], isolated_copy: isolated};
function save() { fs.writeFileSync(path.join(output, 'results.json'), JSON.stringify(metadata, null, 2) + '\n'); }
function run(id, name) {
  const r = cp.spawnSync(process.execPath, [path.join(isolated, testRel)], {cwd: isolated, encoding: 'utf8', windowsHide: true, timeout: 120000});
  if (r.error) throw r.error;
  const log = (r.stdout || '') + (r.stderr || ''); fs.writeFileSync(path.join(output, id + '.log'), log);
  if (!(new RegExp('\\d+/'+testCount+' passed, \\d+ failed')).test(log)) throw new Error(id + ': missing exact case count');
  if (name && !log.includes('FAILED ' + name + ' AssertionError:')) throw new Error(id + ': intended named assertion missing');
  if (/FAILED \S+ (?!AssertionError:)\w+:/.test(log)) throw new Error(id + ': runtime exception is not a mutation kill');
  return {id, exit_code: r.status, intended_assertion: name || null, log_sha256: hash(path.join(output, id + '.log'))};
}
function green(id) { const r = run(id); metadata.results.push(r); save(); if (r.exit_code !== 0) throw new Error(id + ': focused suite is not green'); }
green('before');
const mutants = [
  {id: 'fg_denominator_games', from: 'field_goal_fraction: divide(t.field_goals_made, t.field_goals_attempted),',
    to: 'field_goal_fraction: divide(t.field_goals_made, t.games),', test: 'ratio_of_pooled_attempts_and_zero_denominator'},
  {id: 'zero_denominator_not_missing', from: 'b > 0 ? multiplier * a / b : null', to: 'b >= 0 ? multiplier * a / b : null',
    test: 'ratio_of_pooled_attempts_and_zero_denominator'},
  {id: 'touch_check_bypassed', from: "check(r.touches === r.ledger_touches, 'ledger touch denominator mismatch');",
    to: "check(true, 'ledger touch denominator mismatch');", test: 'touch_denominator_corruption_is_rejected'},
  {id: 'paired_baseline_not_resampled', from: "const zero = metrics(totals(sample.filter(r => r.arm === 'baseline')));",
    to: 'const zero = metrics(totals(b));', test: 'bootstrap_retains_paired_clusters_and_is_deterministic'},
  {id: 'multiplicity_adjustment_removed', from: 'const tail = 0.05 / (2 * 14);', to: 'const tail = 0.05 / 2;',
    test: 'multiplicity_interval_is_wider_than_pointwise'},
  {id:'frozen_within_seed_guard_removed',from:"check(r.seed === 9810001 + offset + r.cluster * 4 + r.slot, 'confirmation gameplay seed shifted');",
    to:"check(true, 'confirmation gameplay seed shifted');",test:'coherently_shifted_confirmation_archive_is_rejected'},
  {id:'held_fixed_hash_guard_removed',from:"check(typeof r.teammates_sha256 === 'string' && /^[a-f0-9]{64}$/.test(r.teammates_sha256) &&\n          typeof r.opponent_sha256 === 'string' && /^[a-f0-9]{64}$/.test(r.opponent_sha256), 'missing held-fixed roster hashes');",
    to:"check(true, 'missing held-fixed roster hashes');",test:'missing_both_control_hashes_is_rejected'},
  {id:'catalog_opener_guard_removed',from:"check(r.subject_opens === (r.subject_home === (r.variation % 2 === 0)), 'catalog opener counterbalance changed');",
    to:"check(true, 'catalog opener counterbalance changed');",test:'coherently_flipped_catalog_openers_are_rejected'},
  {id:'college_career_guard_removed',from:"check(r.career_seed === 9840001 + offset + r.cluster * 20 + side * 10 + index, 'natural college career seed shifted');",
    to:"check(true, 'natural college career seed shifted');",test:'natural_college_career_ranges_are_enforced'},
  {id:'fixture_histogram_oracle_guard_removed',from:"check(oracle(r.values).display === r.current_ovr, 'fixture histogram OVR disagrees with oracle');",
    to:"check(true, 'fixture histogram OVR disagrees with oracle');",test:'second_histogram_payload_formula_corruption_is_rejected'},
];
const file = path.join(isolated, sourceRel), original = fs.readFileSync(file);
for (const m of mutants) {
  const source = original.toString('utf8');
  if (source.split(m.from).length !== 2) throw new Error(m.id + ': exact site missing');
  try {
    fs.writeFileSync(file, source.replace(m.from, m.to));
    const r = run(m.id, m.test); metadata.results.push(r); save();
    if (r.exit_code !== 1) throw new Error(m.id + ': mutant survived');
    process.stdout.write(m.id + ' killed by ' + m.test + '\n');
  } finally { fs.writeFileSync(file, original); }
  green('after_' + m.id);
}
for (const f of [sourceRel, testRel]) if (hash(path.join(root, f)) !== hashes[f] || hash(path.join(isolated, f)) !== hashes[f])
  throw new Error('source changed during mutation run');
metadata.killed = mutants.length; save();
process.stdout.write(JSON.stringify({killed: metadata.killed, output}) + '\n');
