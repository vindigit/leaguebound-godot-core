import fs from 'node:fs';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';

const hash = data => crypto.createHash('sha256').update(data).digest('hex');
const git = (...args) => execFileSync('git', args, {encoding:'utf8'}).trim();
const instrumentFiles = [
  'calibration/harness/margin_growth_audit.gd',
  'calibration/runners/run_margin_growth_followup.gd',
  'calibration/harness/team_strength_index.gd',
  'calibration/harness/calibration_cli.gd',
  'analysis/margin_growth_followup/PROTOCOL.md',
];
const productionFiles = git('ls-files', 'src', 'calibration/targets')
  .split(/\r?\n/).filter(Boolean).sort();
const fingerprints = Object.fromEntries([...instrumentFiles, ...productionFiles].map(file => [file, hash(fs.readFileSync(file))]));
const contents = {
  capture_note: 'Captured after four cells launched and before completion; audited source files were frozen before launch. Git commit identifies the tracked baseline.',
  capture_utc: new Date().toISOString(),
  git_head: git('rev-parse','HEAD'),
  godot_version: '4.7.1.stable.official.a13da4feb',
  command: 'Godot_v4.7.1-stable_win64_console.exe --headless --path . --script res://calibration/runners/run_margin_growth_followup.gd -- --first=FIRST --games=40 --competition=COMPETITION --label=LABEL',
  cells: [
    {label:'range_a', first:43290000, games:40, competition:'college'},
    {label:'range_a', first:43290000, games:40, competition:'top_domestic_pro'},
    {label:'range_b', first:47970000, games:40, competition:'college'},
    {label:'range_b', first:47970000, games:40, competition:'top_domestic_pro'},
  ],
  fingerprints,
  production_manifest_sha256: hash(productionFiles.map(file => `${file}\t${fingerprints[file]}\n`).join('')),
};
fs.writeFileSync('analysis/margin_growth_followup/RUN_PROVENANCE.json', JSON.stringify(contents,null,2)+'\n');
console.log(JSON.stringify({head:contents.git_head, production_files:productionFiles.length, production_manifest_sha256:contents.production_manifest_sha256}));
