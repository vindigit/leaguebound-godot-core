/* Usage: node tools/run_ovr_truthfulness_mutations.cjs GODOT_EXE [OUTPUT_DIRECTORY]
 * Isolated actual-source mutations; named assertion failures with exact case
 * count are required. Parse/runtime errors and crashes never count as kills.
 */
'use strict';
const fs = require('node:fs'), path = require('node:path'), os = require('node:os');
const crypto = require('node:crypto'), cp = require('node:child_process');
const root = path.resolve(__dirname, '..'), godot = path.resolve(process.argv[2] || '');
if (!process.argv[2] || !fs.statSync(godot).isFile()) throw new Error('Provide an existing Godot executable');
const output = path.resolve(root, process.argv[3] || 'analysis/ovr_truthfulness_followup/mutations');
if (!output.startsWith(root + path.sep)) throw new Error('Output must remain under repository');
fs.mkdirSync(output, {recursive: true});
const isolated = fs.mkdtempSync(path.join(os.tmpdir(), 'leaguebound-ovr-truthfulness-'));
for (const name of ['project.godot', 'src', 'tests', 'calibration', 'tools', 'addons'])
  fs.cpSync(path.join(root, name), path.join(isolated, name), {recursive: true});
const files = ['src/domain/basketball/ratings/overall_calculator.gd', 'calibration/harness/ovr_truthfulness_audit.gd',
  'tests/calibration/test_ovr_truthfulness_audit.gd'];
const sha = f => crypto.createHash('sha256').update(fs.readFileSync(f)).digest('hex');
const hashes = Object.fromEntries(files.map(f => [f, sha(path.join(root, f))]));
const metadata = {source_commit: cp.execFileSync('git', ['-C', root, 'rev-parse', 'HEAD'], {encoding: 'utf8', windowsHide: true}).trim(),
  started_utc: new Date().toISOString(), godot: cp.execFileSync(godot, ['--version'], {encoding: 'utf8', windowsHide: true}).trim(),
  isolated_copy: isolated, source_sha256: hashes, results: []};
function save() { fs.writeFileSync(path.join(output, 'results.json'), JSON.stringify(metadata, null, 2) + '\n'); }
function run(id, args, requiredName) {
  const r = cp.spawnSync(godot, args, {cwd: isolated, encoding: 'utf8', windowsHide: true, timeout: 300000, maxBuffer: 32 * 1024 * 1024});
  const log = (r.stdout || '') + (r.stderr || '');
  fs.writeFileSync(path.join(output, id + '.log'), log);
  const clean = log.replace(/\x1b\[[0-9;]*[A-Za-z]/g, '');
  if (r.error || /SCRIPT ERROR|Parse Error|No test cases found/.test(clean)) throw new Error(id + ': invalid execution, not an assertion kill');
  const summary = /Overall Summary: ([^\r\n]+)/.exec(clean)?.[1] || '';
  if (requiredName !== undefined) {
    if (!/14 test cases \| 0 errors \| \d+ failures/.test(summary)) throw new Error(id + ': missing exact focused test count');
    if (requiredName && !(clean.includes(' > ' + requiredName + ' FAILED') && clean.includes("at '" + requiredName + "' in res://")))
      throw new Error(id + ': intended named assertion not reported');
  }
  return {id, exit_code: r.status, summary, intended_assertion: requiredName || null, log_sha256: sha(path.join(output, id + '.log'))};
}
const importResult = run('import', ['--headless', '--path', isolated, '--import']);
if (importResult.exit_code !== 0) throw new Error('isolated import failed');
const args = ['--headless', '--path', isolated, '-s', 'addons/gdUnit4/bin/GdUnitCmdTool.gd', '--ignoreHeadlessMode',
  '-a', 'tests/calibration/test_ovr_truthfulness_audit.gd', '-c'];
function green(id) {
  const r = run(id, args, ''); metadata.results.push(r); save();
  if (r.exit_code !== 0 || !/14 test cases \| 0 errors \| 0 failures/.test(r.summary)) throw new Error(id + ': focused baseline not green');
}
green('before');
const mutants = [
  {id: 'formula_offset', file: files[0], from: 'profile.mean_weight * mean_all', to: 'profile.mean_weight * mean_all + 1.0', test: 'test_exact_formula_matches_independent_rational_oracle'},
  {id: 'floor_instead_of_round', file: files[0], from: 'return int(roundf(clampf(', to: 'return int(floorf(clampf(', test: 'test_exact_half_rounding_neighbor_and_helper_clamping'},
  {id: 'potential_wrong_exact_cap', file: files[0], from: 'var cap_values: Array[int] = caps.values()',
    to: 'var cap_values: Array[int] = caps.values()\n\tcap_values[0] = 25', test: 'test_exact_caps_use_same_formula_and_do_not_change_current'},
  {id: 'repeated_gameplay_seed', file: files[1], from: 'seed_first + cluster * 4 + slot', to: 'seed_first + cluster * 4',
    test: 'test_balanced_schedule_detects_duplicates_and_missing_exposure'},
  {id: 'touch_denominator_offset', file: files[1], from: 'row[String(key)] = line.get(String(key))',
    to: 'row[String(key)] = line.get(String(key))\n\t\tif key == "touches": row["touches"] = (row["touches"] as int) + 1',
    test: 'test_live_measurement_denominators_counts_and_determinism'},
];
for (const mutant of mutants) {
  const file = path.join(isolated, mutant.file), original = fs.readFileSync(file);
  const source = original.toString('utf8').replaceAll('\r\n', '\n');
  if (source.split(mutant.from).length !== 2) throw new Error(mutant.id + ': exact mutation site missing');
  try {
    fs.writeFileSync(file, source.replace(mutant.from, mutant.to));
    const r = run(mutant.id, args, mutant.test); metadata.results.push(r); save();
    if (r.exit_code !== 100 || !/14 test cases \| 0 errors \| [1-9]\d* failures/.test(r.summary)) throw new Error(mutant.id + ': mutation survived');
    process.stdout.write(mutant.id + ' killed by ' + mutant.test + '\n');
  } finally { fs.writeFileSync(file, original); }
  green('after_' + mutant.id);
}
for (const file of files) if (sha(path.join(root, file)) !== hashes[file] || sha(path.join(isolated, file)) !== hashes[file])
  throw new Error('source changed during isolated mutation run: ' + file);
metadata.killed = mutants.length; metadata.finished_utc = new Date().toISOString(); save();
process.stdout.write(JSON.stringify({killed: metadata.killed, results: path.join(output, 'results.json')}) + '\n');
