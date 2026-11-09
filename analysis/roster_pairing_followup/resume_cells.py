"""Resume only the uncompleted, predeclared validation cells after interruption.

Completed process records are checked against their exact raw/report archives.
Interrupted stdout is kept in interrupted_20260922; original seed ranges and
cell labels are reused. No observations or verdicts select the work queue.
"""
import concurrent.futures
import hashlib
import json
import traceback
from datetime import datetime, timezone
from pathlib import Path

import run_cells

OUT = Path(__file__).resolve().parent
PHASES = ('validation_a', 'validation_b')
VERSIONS = ('baseline', 'candidate')
ARMS = ('home', 'neutral')
RESULT = OUT / 'resume_result.json'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def all_cells():
    return [(p, v, c, a) for p in PHASES for v in VERSIONS
            for c in run_cells.COMPS for a in ARMS]


def completion(cell):
    p, v, c, a = cell
    label = f'{p}_{v}_{a}_{c}'
    record_path = OUT / 'processes' / f'{label}.json'
    if not record_path.exists():
        assert not (OUT / 'logs' / f'{label}.txt').exists(), f'Unarchived partial log: {label}'
        assert not (OUT / 'reports' / f'roster_raw_{label}_{c}.json').exists(), f'Unrecorded raw: {label}'
        assert not (OUT / 'reports' / f'competition_calibration_{label}.json').exists(), f'Unrecorded report: {label}'
        return False
    r = json.loads(record_path.read_text(encoding='utf-8-sig'))
    assert r['cell'] == list(cell) and r['exit_code'] in (0, 1), f'Invalid completed cell: {label}'
    raw_path = OUT / 'reports' / f'roster_raw_{label}_{c}.json'
    report_path = OUT / 'reports' / f'competition_calibration_{label}.json'
    log_path = OUT / 'logs' / f'{label}.txt'
    assert log_path.exists() and raw_path.exists() and report_path.exists(), f'Incomplete archive: {label}'
    assert sha(raw_path) == r['raw_sha256'] and sha(report_path) == r['report_sha256'], f'Hash mismatch: {label}'
    raw = json.loads(raw_path.read_text(encoding='utf-8-sig'))
    start = run_cells.SHARDS[p] * 468
    assert len(raw['rows']) == 468, f'Count mismatch: {label}'
    assert [x['variation'] for x in raw['rows']] == list(range(start, start + 468)), f'Variation mismatch: {label}'
    assert all(x['seed'] == x['variation'] + 1 for x in raw['rows']), f'Seed mismatch: {label}'
    tree = run_cells.BASE if v == 'baseline' else run_cells.ROOT
    for path, expected in r['source_hashes'].items():
        assert sha(tree / path).lower() == expected.lower(), f'Source drift: {label} {path}'
    return True


def main():
    if not __debug__:
        raise RuntimeError('Do not optimize Python; completion guards use assertions')
    if RESULT.exists():
        raise RuntimeError('A resume result already exists; preserve it before any further attempt')
    started = datetime.now(timezone.utc).isoformat()
    cells = all_cells()
    kept = [cell for cell in cells if completion(cell)]
    missing = [cell for cell in cells if cell not in kept]
    assert len(cells) == 40 and len(kept) == 5 and len(missing) == 35, 'Unexpected interruption inventory'
    print(f'Resume: {len(kept)} completed cells preserved; {len(missing)} exact missing cells to run', flush=True)
    status = {'started_utc': started, 'kept_cells': kept, 'missing_cells': missing,
              'interrupted_logs': sorted(x.name for x in (OUT / 'interrupted_20260922').glob('validation*.txt'))}
    assert len(status['interrupted_logs']) == 5, 'Unexpected interrupted-log inventory'
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:
            list(pool.map(run_cells.run_cell, missing))
        assert all(completion(cell) for cell in cells), 'Incomplete final validation archive'
        status['verdict'] = 'COMPLETE 40 declared validation cells'
    except BaseException as exc:
        status['verdict'] = 'FAILED, preserve partial state'
        status['error'] = repr(exc)
        status['traceback'] = traceback.format_exc()
        raise
    finally:
        status['completed_utc'] = datetime.now(timezone.utc).isoformat()
        with RESULT.open('x', encoding='utf-8', newline='\n') as stream:
            json.dump(status, stream, indent=2)
            stream.write('\n')


if __name__ == '__main__':
    main()
