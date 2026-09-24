"""Bounded exact-row replay. Planning is the default; --execute runs 80 games.

Run only after all experiment cells and CPU-intensive gates have finished.
No metric judgments are interpreted. Original reports are never overwritten.
"""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import time
from pathlib import Path

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
COMPS = ('high_school', 'college', 'development', 'overseas', 'top_domestic_pro')
PHASES = ('diagnosis', 'validation_a', 'validation_b')
VERSIONS = ('baseline', 'candidate')
ARMS = ('home', 'neutral')


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'),
                      parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))


def write_new(path, value):
    with path.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(value, stream, indent=2, allow_nan=False)
        stream.write('\n')


def canonical(value):
    # Preserve JSON numeric representation (1 versus 1.0), ignore object order.
    return json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False)


def option(args, name):
    prefix = '--' + name + '='
    values = [value[len(prefix):] for value in args if value.startswith(prefix)]
    require(len(values) == 1, f'Expected exactly one {prefix} in original command')
    return values[0]


def paths(label, comp):
    return f'roster_raw_{label}_{comp}.json', f'competition_calibration_{label}.json'


def archived_cell(phase, version, comp, arm, protocol):
    label = f'{phase}_{version}_{arm}_{comp}'
    record_path = OUT / 'processes' / (label + '.json')
    record = read_json(record_path)
    require(record['cell'] == [phase, version, comp, arm], f'Wrong identity: {label}')
    require(record['exit_code'] in (0, 1), f'Incomplete original process: {label}')
    raw_name, report_name = paths(label, comp)
    raw_path, report_path = OUT / 'reports' / raw_name, OUT / 'reports' / report_name
    require(digest(raw_path) == record['raw_sha256'], f'Original raw hash drift: {label}')
    require(digest(report_path) == record['report_sha256'], f'Original report hash drift: {label}')
    raw = read_json(raw_path)
    base = int(protocol['phases'][phase])
    require(len(raw['rows']) == 468, f'Original cell is not complete: {label}')
    require([row['variation'] for row in raw['rows']] == list(range(base, base + 468)),
            f'Original variations differ: {label}')
    require(all(row['seed'] == row['variation'] + 1 for row in raw['rows']),
            f'Original seeds differ: {label}')
    args = record['args']
    require(int(option(args, 'games')) == 468 and int(option(args, 'shard')) * 468 == base,
            f'Original shard math differs: {label}')
    require(option(args, 'competition') == comp and option(args, 'label') == label,
            f'Original command identity differs: {label}')
    environment = 0.5 if arm == 'home' else 0.0
    require(float(option(args, 'environment')) == environment and raw['environment'] == environment,
            f'Original environment differs: {label}')
    require(raw['competition'] == comp and raw['seed_first'] == base + 1
            and raw['seed_last'] == base + 468, f'Original metadata differs: {label}')
    return record_path, record, raw_path, raw


def source_hashes(tree):
    files = sorted({path for directory in ('src', 'calibration')
                    for path in (tree / directory).rglob('*.gd')})
    return {path.relative_to(tree).as_posix(): digest(path) for path in files}


def plan_cell(version, comp, arm, run_id, protocol):
    base = int(protocol['phases']['diagnosis'])
    require(base % 4 == 0, 'Diagnosis prefix is not quartet aligned')
    label = f'replay_prefix_{run_id}_{version}_{arm}_{comp}'
    # The runner computes base=shard*games, not shard*468 unconditionally.
    shard = base // 4
    return {'cell': ['diagnosis', version, comp, arm], 'label': label,
            'games': 4, 'shard': shard, 'shards': shard + 1,
            'variations': list(range(base, base + 4)),
            'seeds': list(range(base + 1, base + 5))}


def replay(plan, destination, protocol, freeze, timeout):
    _, version, comp, arm = plan['cell']
    record_path, original, raw_path, raw = archived_cell('diagnosis', version, comp, arm, protocol)
    args = list(original['args'])
    tree = Path(args[args.index('--path') + 1])
    require(tree.is_dir(), f'Original source tree missing: {tree}')
    replacements = {'games': '4', 'shard': str(plan['shard']),
                    'shards': str(plan['shards']), 'label': plan['label']}
    for index, value in enumerate(args):
        if value.startswith('--') and '=' in value:
            name = value[2:].split('=', 1)[0]
            if name in replacements:
                args[index] = '--' + name + '=' + replacements[name]
    before = source_hashes(tree)
    amendment_path = OUT / 'consumer_width_amendment.json'
    amendment = read_json(amendment_path) if version == 'candidate' else None
    amendment_hash = digest(amendment_path) if amendment is not None else None
    if amendment is not None:
        consumer = 'calibration/runners/run_home_court_diagnostics.gd'
        require(amendment['approved'] is True and amendment['version'] == 'candidate'
                and amendment['path'] == consumer, 'Unapproved or overbroad freeze amendment')
        require(amendment['old_sha256'] == freeze['files'][consumer]['candidate'].lower(),
                'Consumer amendment does not match original freeze')
        require(digest(OUT / 'candidate_freeze.json') == amendment['original_freeze_sha256']
                and digest(OUT / 'mirror_boundary/provenance.json') == amendment['probe_provenance_sha256'],
                'Consumer amendment provenance changed')
        require(before.get(consumer) == amendment['new_sha256'], 'Amended consumer hash differs')
        for path, expected in amendment['unchanged_primary_and_other_runtime_hashes'].items():
            require(digest(tree / path) == expected, f'Other runtime drift after amendment: {path}')
    for path, expected in original['source_hashes'].items():
        require(before.get(path) == expected.lower(), f'Original source hash differs: {version}/{path}')
    for path, expected in freeze['files'].items():
        if path.endswith('.gd') and path.startswith(('src/', 'calibration/')):
            # The original cell records the reviewed catalog comment amendment.
            wanted = original['source_hashes'].get(path, expected[version])
            if amendment is not None and path == amendment['path']:
                wanted = amendment['new_sha256']
            require(before.get(path) == wanted.lower(), f'Frozen runtime source differs: {version}/{path}')
    raw_name, report_name = paths(plan['label'], comp)
    generated = [tree / 'reports' / name for name in (raw_name, report_name)]
    require(all(not path.exists() for path in generated), 'Replay output label already exists')
    cell_dir = destination / plan['label']
    cell_dir.mkdir()
    prefix = raw['rows'][:4]
    write_new(cell_dir / 'expected_rows.json', prefix)
    command = dict(plan, args=args, cwd=str(tree), source_hashes=before,
                   godot_sha256=digest(Path(args[0])),
                   original_process_sha256=digest(record_path), original_raw_sha256=digest(raw_path),
                   original_record=str(record_path), original_raw=str(raw_path),
                   consumer_width_amendment_sha256=amendment_hash,
                   script_sha256=digest(Path(__file__)), expected_rows_sha256=digest(cell_dir / 'expected_rows.json'))
    write_new(cell_dir / 'command.json', command)
    started = time.time()
    outcome = {'completed': False, 'exact_match': False, 'started_unix': started,
               'exit_code': None, 'diffs': [], 'artifacts': {}}
    failure = None
    try:
        with (cell_dir / 'process.log').open('x', encoding='utf-8') as log:
            with subprocess.Popen(args, cwd=tree, stdout=log, stderr=subprocess.STDOUT,
                                  creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0)) as process:
                try:
                    code = process.wait(timeout=timeout)
                except subprocess.TimeoutExpired:
                    # Godot's Windows console wrapper has a child engine process.
                    if os.name == 'nt':
                        subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                                       stdout=log, stderr=subprocess.STDOUT,
                                       creationflags=subprocess.CREATE_NO_WINDOW, check=False)
                    process.kill()
                    process.wait()
                    outcome['exit_code'] = process.returncode
                    outcome['timed_out'] = True
                    raise
        outcome['exit_code'] = code
        require(code in (0, 1), f'Replay process exit {code}')
        text = (cell_dir / 'process.log').read_text(encoding='utf-8', errors='replace')
        require('Godot Engine v4.7.1.stable.official.a13da4feb' in text, 'Unexpected Godot version')
        require(re.search(r'\b(?:SCRIPT ERROR|Parse Error|ERROR|FATAL|Exception|Traceback|WARNING)\b', text, re.I) is None,
                'Replay contains engine/script errors or warnings')
        replay_raw = read_json(generated[0])
        read_json(generated[1])  # Both output documents must be complete JSON.
        require(len(replay_raw['rows']) == 4, 'Replay did not complete four games')
        require(replay_raw['competition'] == raw['competition']
                and replay_raw['catalog'] == raw['catalog']
                and replay_raw['environment'] == raw['environment']
                and replay_raw['seed_first'] == plan['seeds'][0]
                and replay_raw['seed_last'] == plan['seeds'][-1], 'Replay metadata mismatch')
        for index, (expected, actual) in enumerate(zip(prefix, replay_raw['rows'])):
            if canonical(expected) != canonical(actual):
                keys = sorted(set(expected) | set(actual))
                outcome['diffs'].append({'index': index, 'variation': plan['variations'][index],
                    'fields': [key for key in keys if key not in expected or key not in actual
                               or canonical(expected[key]) != canonical(actual[key])],
                    'expected': expected, 'actual': actual})
        outcome['completed'] = True
        require(not outcome['diffs'], 'Exact raw row replay mismatch')
        require(source_hashes(tree) == before, 'Runtime source changed during replay')
        if amendment is not None:
            require(digest(amendment_path) == amendment_hash, 'Consumer amendment changed during replay')
        require(digest(Path(args[0])) == command['godot_sha256'], 'Godot executable changed during replay')
        require(digest(raw_path) == command['original_raw_sha256']
                and digest(record_path) == command['original_process_sha256'], 'Original archive changed during replay')
        outcome['exact_match'] = True
    except Exception as error:
        failure = error
        outcome['error'] = f'{type(error).__name__}: {error}'
    finally:
        for path in generated:
            if path.exists():
                target = cell_dir / path.name
                shutil.copy2(path, target)
                outcome['artifacts'][path.name] = digest(target)
        outcome['source_hashes_after'] = source_hashes(tree)
        outcome['elapsed_seconds'] = time.time() - started
        outcome['log_sha256'] = digest(cell_dir / 'process.log') if (cell_dir / 'process.log').exists() else None
        write_new(cell_dir / 'result.json', outcome)
    if failure is not None:
        raise failure
    return {'cell': plan['cell'], 'directory': str(cell_dir), 'result_sha256': digest(cell_dir / 'result.json')}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run-id', required=True, help='Unique safe label; never reuse it')
    parser.add_argument('--execute', action='store_true', help='Run only after experiment and heavy gates finish')
    parser.add_argument('--timeout-seconds', type=int, default=600)
    opts = parser.parse_args()
    require(re.fullmatch(r'[A-Za-z0-9_-]{1,48}', opts.run_id) is not None, 'Unsafe run id')
    require(opts.timeout_seconds > 0, 'Timeout must be positive')
    protocol = read_json(OUT / 'protocol.json')
    plans = [plan_cell(version, comp, arm, opts.run_id, protocol)
             for version in VERSIONS for comp in COMPS for arm in ARMS]
    if not opts.execute:
        print(json.dumps({'execute': False, 'cells': 20, 'games': 80, 'plans': plans}, indent=2))
        return
    # Read-only completeness barrier: all 60 preregistered experiment cells.
    for phase in PHASES:
        for version in VERSIONS:
            for comp in COMPS:
                for arm in ARMS:
                    archived_cell(phase, version, comp, arm, protocol)
    destination = OUT / 'replay_prefixes' / opts.run_id
    destination.mkdir(parents=True, exist_ok=False)
    freeze = read_json(OUT / 'candidate_freeze.json')
    write_new(destination / 'plan.json', {'cells': plans, 'total_games': 80,
              'protocol_sha256': digest(OUT / 'protocol.json'), 'freeze_sha256': digest(OUT / 'candidate_freeze.json')})
    results = []
    try:
        for plan in plans:  # Sequential, deliberately bounded CPU demand.
            results.append(replay(plan, destination, protocol, freeze, opts.timeout_seconds))
            print('MATCH ' + plan['label'], flush=True)
    except Exception as error:
        write_new(destination / 'summary.json', {'success': False, 'completed_cells': results,
                  'error': f'{type(error).__name__}: {error}'})
        raise
    write_new(destination / 'summary.json', {'success': True, 'completed_cells': results,
              'cells': 20, 'games': 80, 'comparison': 'Every complete raw per-game row, exact canonical JSON; no tolerance'})


if __name__ == '__main__':
    main()
