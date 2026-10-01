'use strict';
// Read-only provenance capture. Run before starting measurements.
const fs = require('node:fs');
const path = require('node:path');
const cp = require('node:child_process');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const run = (cmd, args) => cp.execFileSync(cmd, args, {cwd: root, encoding: 'utf8', windowsHide: true}).trim();
const expected = '899a3972e48e8ce63de07b47b2e593e9c97df4d2';
const head = run('git', ['rev-parse', 'HEAD']);
const files = run('git', ['ls-files', 'src', 'calibration/targets', 'tests/golden']).split(/\r?\n/);
const payload = {
  schema: 'leaguebound.stage4.baseline/1', captured_utc: new Date().toISOString(), expected_head: expected,
  git: {head, status: run('git', ['status', '--porcelain=v1', '--branch']),
    remote: run('git', ['ls-remote', 'origin', 'refs/heads/stage4-calibration'])},
  production_tree: run('git', ['rev-parse', 'HEAD:src']),
  target_tree: run('git', ['rev-parse', 'HEAD:calibration/targets']),
  golden_tree: run('git', ['rev-parse', 'HEAD:tests/golden']),
  production_source_sha256: Object.fromEntries(files.map(f => [f,
    crypto.createHash('sha256').update(fs.readFileSync(path.join(root, f))).digest('hex')])),
  pr: JSON.parse(run('gh', ['pr', 'view', '1', '--repo', 'vindigit/leaguebound-godot-core',
    '--json', 'number,state,isDraft,headRefOid,headRefName,baseRefName,url'])),
  check_runs: JSON.parse(run('gh', ['api', `repos/vindigit/leaguebound-godot-core/commits/${head}/check-runs`]))
    .check_runs.map(({name, head_sha, status, conclusion, details_url}) => ({name, head_sha, status, conclusion, details_url})),
  note: 'Expected SHA is a verification precondition; this tool never changes git state. Untracked report tooling may already exist at capture.'
};
const destination = path.resolve(root, process.argv[2] || 'analysis/stage4_blocker_review/baseline.json');
fs.mkdirSync(path.dirname(destination), {recursive: true});
fs.writeFileSync(destination, JSON.stringify(payload, null, 2) + '\n');
process.stdout.write(JSON.stringify({head, files: files.length, destination}) + '\n');
