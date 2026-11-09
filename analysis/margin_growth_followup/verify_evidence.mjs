import fs from 'node:fs';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';

const digest = data => crypto.createHash('sha256').update(data).digest('hex');
const hashFile = file => digest(fs.readFileSync(file));
const provenance = JSON.parse(fs.readFileSync('analysis/margin_growth_followup/RUN_PROVENANCE.json'));
const head = execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();
execFileSync('git',['merge-base','--is-ancestor',provenance.git_head,head]);
for (const [file,expected] of Object.entries(provenance.fingerprints))
  if (hashFile(file) !== expected) throw new Error(`source drift: ${file}`);
const raw = [
  'range_a_college.ndjson','range_a_top_domestic_pro.ndjson',
  'range_b_college.ndjson','range_b_top_domestic_pro.ndjson',
].map(name => `analysis/margin_growth_followup/raw/${name}`);
const summary='analysis/margin_growth_followup/summary.json';
const firstHash=hashFile(summary);
execFileSync('node',['analysis/margin_growth_followup/summarize.mjs',...raw],{stdio:'pipe'});
if (hashFile(summary)!==firstHash) throw new Error('summary recomputation changed bytes');
const artifacts=[
  ...raw,summary,
  'analysis/margin_growth_followup/PROTOCOL.md',
  'analysis/margin_growth_followup/RUN_PROVENANCE.json',
  'analysis/margin_growth_followup/excluded_probe_top_domestic_pro.ndjson',
  'analysis/margin_growth_followup/competition_calibration_current_40_each.json',
  'analysis/margin_growth_followup/focused_builder_tests.log',
  'analysis/margin_growth_followup/mutations/results.json',
];
for (const optional of ['full_gate.log','full_gate_exit.txt']) {
  const file=`analysis/margin_growth_followup/${optional}`;
  if(fs.existsSync(file))artifacts.push(file);
}
const result={
  verified_utc:new Date().toISOString(),starting_head:provenance.git_head,verified_head:head,
  source_files_checked:Object.keys(provenance.fingerprints).length,
  production_manifest_sha256:provenance.production_manifest_sha256,
  summary_recomputed_identical:true,
  artifacts:Object.fromEntries(artifacts.map(file=>[file,{bytes:fs.statSync(file).size,sha256:hashFile(file)}])),
};
fs.writeFileSync('analysis/margin_growth_followup/EVIDENCE_MANIFEST.json',JSON.stringify(result,null,2)+'\n');
console.log(JSON.stringify({checked:result.source_files_checked,raw:raw.length,summary_sha256:result.artifacts[summary].sha256}));
