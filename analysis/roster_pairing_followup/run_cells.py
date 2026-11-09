"""Run fixed, preregistered cells without filtering by measured verdicts."""
import argparse, concurrent.futures, hashlib, json, os, shutil, subprocess, time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'analysis/roster_pairing_followup'
GODOT = Path(r'C:\Users\valexander\Downloads\Godot_v4.7.1-stable_win64.exe\Godot_v4.7.1-stable_win64_console.exe')
BASE = Path(os.environ['TEMP']) / 'leaguebound-roster-baseline-11c4eae'
COMPS = ['high_school', 'college', 'development', 'overseas', 'top_domestic_pro']
SHARDS = {'diagnosis': 50000, 'validation_a': 60000, 'validation_b': 70000}

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def run_cell(cell):
    phase, version, comp, arm = cell
    tree = BASE if version == 'baseline' else ROOT
    label = f'{phase}_{version}_{arm}_{comp}'
    raw_name = f'roster_raw_{label}_{comp}.json'
    report_name = f'competition_calibration_{label}.json'
    for name in [raw_name, report_name]:
        if (tree / 'reports' / name).exists() or (OUT / 'reports' / name).exists():
            raise RuntimeError(f'Refusing to overwrite completed cell {name}')
    args = [str(GODOT), '--headless', '--path', str(tree), '--script',
            'res://calibration/runners/run_roster_pairing_followup.gd', '--',
            '--games=468', f'--competition={comp}', f'--shard={SHARDS[phase]}',
            f'--shards={SHARDS[phase]+1}', f'--environment={0.5 if arm == "home" else 0.0}',
            f'--label={label}']
    started = time.time()
    provenance = {p: digest(tree / p) for p in [
        'calibration/targets/competition_catalog.gd',
        'calibration/runners/run_roster_pairing_followup.gd',
        'src/domain/basketball/config/competition_rule_profile.gd']}
    with (OUT / 'logs' / f'{label}.txt').open('w', encoding='utf-8') as log:
        result = subprocess.run(args, cwd=tree, stdout=log, stderr=subprocess.STDOUT,
                                creationflags=subprocess.CREATE_NO_WINDOW)
    raw = json.loads((tree / 'reports' / raw_name).read_text(encoding='utf-8-sig'))
    assert len(raw['rows']) == 468
    assert [r['variation'] for r in raw['rows']] == list(range(SHARDS[phase]*468, (SHARDS[phase]+1)*468))
    assert all(r['seed'] == r['variation'] + 1 for r in raw['rows'])
    assert result.returncode in (0, 1), result.returncode
    for p, expected in provenance.items():
        assert digest(tree / p) == expected, f'Source changed during cell: {p}'
    for name in [raw_name, report_name]:
        shutil.copy2(tree / 'reports' / name, OUT / 'reports' / name)
    record = {'cell': cell, 'args': args, 'exit_code': result.returncode,
              'elapsed_seconds': time.time()-started, 'started_unix': started,
              'source_hashes': provenance, 'raw_sha256': digest(OUT/'reports'/raw_name),
              'report_sha256': digest(OUT/'reports'/report_name)}
    (OUT / 'processes' / f'{label}.json').write_text(json.dumps(record, indent=2)+'\n')
    print(f'COMPLETE {label} exit={result.returncode} seconds={record["elapsed_seconds"]:.1f}', flush=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--phases', nargs='+', choices=SHARDS, required=True)
    parser.add_argument('--versions', nargs='+', choices=['baseline','candidate'], required=True)
    parser.add_argument('--workers', type=int, default=6)
    opts = parser.parse_args()
    for directory in ['reports', 'logs', 'processes']:
        (OUT / directory).mkdir(parents=True, exist_ok=True)
    cells = [(p,v,c,a) for p in opts.phases for v in opts.versions for c in COMPS for a in ['home','neutral']]
    with concurrent.futures.ThreadPoolExecutor(max_workers=opts.workers) as pool:
        list(pool.map(run_cell, cells))
